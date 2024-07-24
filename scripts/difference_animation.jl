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
#B
grid = "horz_ndg_cut_PG_819x117"
pdisc1 = "hybrid-avgmpfa"
pdisc2 = "leftFaultEntry-hybrid-avgmpfa"

folder_path = output_folder*"B_deck=B_ISO_C_grid="*grid*"_pdisc="*pdisc1
folder_path_2 = output_folder*"B_deck=B_ISO_C_grid="*grid*"_pdisc="*pdisc2
# folder_path = output_folder*"B_deck=B_ISO_C_grid=cPEBI_2640x380"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=struct819x117"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=cPEBI_819x117"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=horz_ndg_cut_PG_819x117"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=horz_ndg_cut_PG_130x62"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=cart_ndg_cut_PG_819x117"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=gq_pb0.19"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=5tetRef0.31"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=horz_ndg_cut_PG_819x117_schedule=animationFriendly"

# C
# folder_path = output_folde r*"C_deck=B_ISO_C_grid=struct50x50x50"
# folder_path = output_folder*"C_deck=B_ISO_C_grid=horz_ndg_cut_PG_50x50x50"
# folder_path = output_folder*"C_deck=B_ISO_C_grid=cart_ndg_cut_PG_50x50x50"
# folder_path = output_folder*"C_deck=B_ISO_C_grid=struct100x100x100"
# folder_path = output_folder*"C_deck=B_ISO_C_grid=horz_ndg_cut_PG_100x100x100"
# folder_path = output_folder*"C_deck=B_ISO_C_grid=cart_ndg_cut_PG_100x100x100"

# method = "hybrid-avgmpfa"
# folder_path_2 = split(folder_path, "schedule")[1]*"pdisc="*method*"_schedule=animationFriendly"
# folder_path_2 = folder_path*"_pdisc="*method

animation_name = "B_HNCP-F_hybrid-avgmpfa_vs_LFE-hybrid-avgmpfa"

result = animate_diff(folder_path, folder_path_2,
                    animation_name = animation_name,
                    title = animation_name)



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