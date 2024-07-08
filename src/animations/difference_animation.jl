using JutulDarcy, Jutul, GLMakie
using ProgressMeter
using VideoIO, ImageTransformations
include("read_mrst_output.jl")
include("animate_and_crop.jl")
include("read_big_output.jl")
include("utils.jl")

output_folder = "/media/kristian/HDD/matlab/output/"
# output_folder = "/home/kristian/matlab/output/"

# folder_path = output_folder*"A_deck=RS_grid=5tetRef10_pdisc=ntpfa"

# folder_path = output_folder*"B_deck=B_ISO_C_grid=cPEBI_2640x380"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=struct819x117"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=cPEBI_819x117"
folder_path = output_folder*"B_deck=B_ISO_C_grid=horz_ndg_cut_PG_819x117"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=cart_ndg_cut_PG_819x117"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=cart_ndg_cut_PG_819x117"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=gq_pb0.19"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=5tetRef0.31"

# C
# folder_path = output_folde r*"C_deck=B_ISO_C_grid=struct50x50x50"
# folder_path = output_folder*"C_deck=B_ISO_C_grid=horz_ndg_cut_PG_50x50x50"
# folder_path = output_folder*"C_deck=B_ISO_C_grid=cart_ndg_cut_PG_50x50x50"
# folder_path = output_folder*"C_deck=B_ISO_C_grid=struct100x100x100"
# folder_path = output_folder*"C_deck=B_ISO_C_grid=horz_ndg_cut_PG_100x100x100"
# folder_path = output_folder*"C_deck=B_ISO_C_grid=cart_ndg_cut_PG_100x100x100"

method = "hybrid-avgmpfa"
folder_path_2 = folder_path*"_pdisc="*method

SPEcase = basename(folder_path)[1]
output_path = folder_path*"_output"
## Mock Simulation
case = setup_case_from_mrst(folder_path*".mat");
model = case[1].model;
reservoir_states = read_big_output(output_path)
# reservoir_states, _ = read_results(output_path, read_reports=false);
# for i in eachindex(reservoir_states)
#     reservoir_states[i] = reservoir_states[i][:Reservoir]
# end

reservoir_states_1 = readMRSTOutput(folder_path*"/multiphase")
reservoir_states_2 = readMRSTOutput(folder_path_2*"/multiphase")

num_states = length(reservoir_states_1)
# Calculate difference between states
difference = Vector{Dict{Symbol, Any}}(undef, num_states)
num_cells = model[:Reservoir].data_domain.representation.nc

for i in eachindex(reservoir_states_1)
    difference[i] = Dict(:Rs=> Vector{Float64}(undef, num_cells))
    difference[i][:Rs] =  vec(reservoir_states_1[i] - reservoir_states_2[i])
end
# Format states for Plotting
states1 = Vector{Dict{Symbol, Any}}(undef, num_states)
states2 = Vector{Dict{Symbol, Any}}(undef, num_states)
for i in eachindex(reservoir_states_1)
    states1[i] = Dict(:Rs=> Vector{Float64}(undef, num_cells))
    states2[i] = Dict(:Rs=> Vector{Float64}(undef, num_cells))

    states1[i][:Rs] =  vec(reservoir_states_1[i])
    states2[i][:Rs] =  vec(reservoir_states_2[i])
end
## Plotting
plot_facies = true
# edge_color= :Grey
edge_color = nothing
chosen_states = states1;
name = "B_HNCP-F_diff"

range_regular, max_diff = ranges(states1, difference, states2)
set_theme!(backgroundcolor = :grey, figure_padding = 0)
fig = Figure(resolution = (1590,530))
ax_1 = Axis3(fig[1,1], zreversed=true, azimuth=-pi/2, elevation=0, aspect=(1.0,1.0,1/3), protrusions=1)
ax_diff = Axis3(fig[1,2], zreversed=true, azimuth=-pi/2, elevation=0, aspect=(1.0,1.0,1/3), protrusions=1)
ax_time = Axis(fig[2,1][2,1])
ax_2 = Axis3(fig[2,2], zreversed=true, azimuth=-pi/2, elevation=0, aspect=(1.0,1.0,1/3), protrusions=1)
for ax in [ax_1, ax_diff, ax_2, ax_time]
    hidespines!(ax)
    hidedecorations!(ax)
    ax.xautolimitmargin = (0,0)
    ax.yautolimitmargin = (0,0)
    
    if !isa(ax, Axis); ax.zautolimitmargin = (0,0);end
end
colgap!(fig.layout, 1, 1)
rowgap!(fig.layout, 1, 1)

pts, tri, mapper = triangulate_mesh(model[:Reservoir].data_domain, outer = false)

             
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

matdata = MAT.matread(folder_path*".mat")
G_cells_tag = matdata["G"]["cells"]["tag"]
plot_cell_data!(ax_1, model[:Reservoir].data_domain, G_cells_tag, transparency = false, alpha = 0.1, colormap = :gray1, shading = NoShading)
plot_cell_data!(ax_diff, model[:Reservoir].data_domain, G_cells_tag, transparency = false, alpha = 0.1, colormap = :gray1, shading = NoShading)
plot_cell_data!(ax_2, model[:Reservoir].data_domain, G_cells_tag, transparency = false, alpha = 0.1, colormap = :gray1, shading = NoShading)

#to add in record loop
m_1[:color] = mapper.Cells(states1[i][:Rs])
m_diff[:color] = mapper.Cells(difference[i][:Rs])
m_2[:color] = mapper.Cells(states2[i][:Rs])





#old
fig = plot_reservoir(model[:Reservoir], chosen_states; 
                    shading= NoShading, 
                    edge_color = edge_color)
if plot_facies
    matdata = MAT.matread(folder_path*".mat")
    G_cells_tag = matdata["G"]["cells"]["tag"]
    ax = fig.current_axis[]
    plot_cell_data!(ax, model[:Reservoir].data_domain, G_cells_tag, transparency = false, alpha = 0.1, colormap = :gray1)
end
ax = fig.current_axis.x
hidespines!(ax)
hidedecorations!(ax)
if SPEcase == 'B' || SPEcase == 'A'
    fig.content[18].i_selected = 2 #set scale to all steps, row
    fig.content[20].i_selected = 2 #set camera to xz
    # fig.content[1].i_selected = 3 # set variable to rs
    if occursin("diff", name)
        fig.content[16].i_selected = 2 #set balance colortheme
    end
elseif SPEcase == 'C'
    fig.content[18].i_selected = 2 #set scale to all steps, row
    fig.current_axis.x.azimuth.val = -2.21
    fig.current_axis.x.elevation.val = 0.1
    fig.content[4].selected_indices = (70, 1000) #dont show low values
    fig.content[1].i_selected = 3 # set variable to rs
end

anim_path = animate(fig;animation_name=name, num_steps = 300)
crop_video(anim_path; SPEcase = SPEcase, num_steps=300)

# Plot facies separately
fig = plot_cell_data(model[:Reservoir].data_domain.representation,
 G_cells_tag, transparency = false, alpha = 1, 
 colormap = :viridis, z_is_depth=true,
 colorbar = nothing)
ax = fig[2]
hidespines!(ax)
hidedecorations!(ax)
ax.azimuth = -pi/2
ax.elevation = 0