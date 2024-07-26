## Animation
function animate_diff(path1, path2;
    animation_name = "anim",
    folder = "videos/diffs",
    framerate=24,
    pixels_per_unit = 2,
    compression = 1,
    include_days = false,
    title = "Time since injection start")

    SPEcase = basename(path1)[1]
    ## Read case setup
    case = setup_case_from_mrst(path1*".mat");
    model = case[1].model;

    states1, states2, difference = read_states_and_calc_diff(path1, path2)
    #get max ranges, to not change colorscale during animation
    range_regular, max_diff = ranges(states1, difference, states2)
    
    
    set_theme!(backgroundcolor = :grey, figure_padding = 0)

    h = 1590
    w = 530
    fig = Figure(size = (h,w))
    #Sim in top left
    ax_1 = Axis3(fig[1,1], zreversed=true, azimuth=-pi/2, elevation=0,
                aspect=(1.0,1.0,1/3), protrusions=1)
    #Difference in top right
    ax_diff = Axis3(fig[1,2], zreversed=true, azimuth=-pi/2, elevation=0,
                    aspect=(1.0,1.0,1/3), protrusions=1)
    #progress bar in lower left
    ax_prog = Axis(fig[2,1][2,1], title="Simulation progress",
                    yticksvisible = false, yticklabelsvisible=false,
                    width = Relative(0.8), height = Relative(0.4),
                    halign = :center, valign= :top,
                    tellheight = false, tellwidth = false,
                    xticksvisible = false, xticklabelsvisible=false, alignmode=Outside())
    #Labels in lower left
    lab_time_title = Label(fig[2, 1][1, 1], title, fontsize=30,
                    width=Relative(0.8), height=Relative(0.4),
                    halign=:center, valign=:center, # Changed from :top to :center
                    tellheight=false, tellwidth=false)
    
    lab_time = Label(fig[2, 1][1, 1], format_time(0, include_days=include_days), fontsize=20,
                    width=Relative(0.8), height=Relative(0.4),
                    halign=:center, valign=:bottom, # Changed from :bottom to :center
                    tellheight=false, tellwidth=false)
    # Sim in bottom right
    ax_2 = Axis3(fig[2,2], zreversed=true, azimuth=-pi/2, elevation=0,
                aspect=(1.0,1.0,1/3), protrusions=1)

    #make it pretty
    for ax in [ax_1, ax_diff, ax_2]
        hidespines!(ax)
        hidedecorations!(ax)
        ax.xautolimitmargin = (0,0)
        ax.yautolimitmargin = (0,0)
        
        if !isa(ax, Axis); ax.zautolimitmargin = (0,0);end
    end
    colgap!(fig.layout, 1, 1)
    rowgap!(fig.layout, 1, 1)

    #get map from cell values to mesh colors
    _, _, mapper = triangulate_mesh(model[:Reservoir].data_domain, outer = false)

    #initiate cell data plots
    i = 1     
    m_1 = plot_cell_data!(ax_1, model[:Reservoir].data_domain, states1[i][:Rs], 
                            transparency = false, alpha = 1, colormap = :viridis, 
                            shading = NoShading, colorrange=range_regular)
    m_diff = plot_cell_data!(ax_diff, model[:Reservoir].data_domain, difference[i][:Rs], 
                            transparency = false, alpha = 1, colormap = :balance,
                            shading = NoShading, colorrange=[-max_diff, max_diff])
    m_2 = plot_cell_data!(ax_2, model[:Reservoir].data_domain, states2[i][:Rs],
                        transparency = false, alpha = 1, colormap = :viridis,
                        shading = NoShading, colorrange=range_regular)
    # read setup data
    matdata = MAT.matread(path1*".mat")
    G_cells_tag = matdata["G"]["cells"]["tag"]
    #plot facies
    for ax in [ax_1, ax_diff, ax_2]
        plot_cell_data!(ax, model[:Reservoir].data_domain, G_cells_tag, transparency = false, alpha = 0.1, colormap = :gray1, shading = NoShading)
    end

    #init progressbar
    progress_bar = barplot!(ax_prog, [0.0], direction=:x, xticks = [0, 50, 100],yticks=nothing, color=:green)
    xlims!(ax_prog, [0,112])
    progress_bar.yticks = nothing
    progress_label = text!(ax_prog, "0%", position=Point2f(1, 1), align=(:left, :center), fontsize=16, color=:black)

    dt = matdata["schedule"]["step"]["val"]
    dt[1] = 0 #display time from injection start
    timestamps = cumsum(dt, dims=1)
    if SPEcase != 'A' #adjust for equilibrium step for SPE11B and SPE11C
        stepmodifier = 1
    else 
        stepmodifier = 0
    end
    num_steps = length(dt)

    path = joinpath(pwd(), folder, animation_name*".mp4")
    p = Progress(num_steps, desc="Recording animation...");
    record(fig, path, 1:num_steps; framerate = framerate, px_per_unit=pixels_per_unit, compression = compression) do i
        #Update cell data plots
        m_1[:color] = mapper.Cells(states1[i][:Rs])
        m_diff[:color] = mapper.Cells(difference[i][:Rs])
        m_2[:color] = mapper.Cells(states2[i][:Rs])
        #update progress bar
        progress = (i-stepmodifier) / (num_states-stepmodifier) * 100
        progress_bar[1] = [progress]
        progress_label.position = Point2f(progress + 1, 1)
        progress_label[1] = "$(round(progress, digits=1))%"
        #update time displayed
        lab_time.text = format_time(timestamps[i], include_days=include_days)
        next!(p)
    end
    return path
end


function animate(fig; animation_name="anim", folder = "videos",
    framerate=24,
    pixels_per_unit = 2,
    compression = 1)
    fullpath = joinpath(pwd(), folder, animation_name*".mp4")

    num_steps = length(fig.content[3].range.val)
    p = Progress(num_steps, desc="Recording animation...");
    record(fig.content[5].scene, fullpath, 1:num_steps; framerate = framerate, px_per_unit=pixels_per_unit, compression = compression) do i
        fig.content[3].selected_index = i
        next!(p)
    end
    return fullpath
end

## Crop animation
function crop_video(path;
    framerate = 24,
    SPEcase = 'B')
    video = VideoIO.load(path);
    num_steps = length(video)
    frame = video[num_steps]
    # Define cropping parameters
    ny, nx = size(frame)
    if SPEcase == 'B' || SPEcase == 'A'
        x, y = 110, 200  # Top left corner of the crop
        x2, y2 = 110, 220
    elseif SPEcase == 'C'
        x, y = 110, 200  # Top left corner of the crop
        x2, y2 = 100, 200
    end
    x, x2 = x/1600*nx, x2/1600*nx
    y, y2 = y/900*ny, y2/900*ny
    width, height = nx - x - x2, ny - y - y2  # Width and height of the crop
    x, y, width, height = round.(Int, [x, y, width, height])

    filetype = ".mp4"
    cropped_frame = ImageTransformations.imresize(frame[y:y+height, x:x+width], (height, width))
    path_cropped = joinpath(dirname(path), "cropped", splitext(basename(path))[1]*"_cropped"*filetype)
    writer = VideoIO.open_video_out(path_cropped, cropped_frame; framerate=framerate);
    p = Progress(length(video);desc="Cropping video...");
    for frame in video
        cropped_frame = ImageTransformations.imresize(frame[y:y+height, x:x+width], (height, width))
        VideoIO.write(writer, cropped_frame)
        next!(p)
    end
    VideoIO.close_video_out!(writer);
    return path_cropped
end
