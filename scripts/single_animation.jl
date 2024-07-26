using JutulDarcy, Jutul, GLMakie
using ProgressMeter
using VideoIO, ImageTransformations
using Revise
includet("./../src/animations/preparation.jl")
includet("./../src/animations/animate_and_crop.jl")
includet("./../src/animations/utils.jl")


# output_folder = "/media/kristian/HDD/matlab/output/"
output_folder = "/home/kristian/matlab/output/"

# folder_path = output_folder*"A_deck=RS_grid=5tetRef10_pdisc=ntpfa";name = "A_5tetRef10_ntpfa"

# folder_path = output_folder*"B_deck=B_ISO_C_grid=cPEBI_2640x380"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=struct819x117"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=cPEBI_819x117"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=horz_ndg_cut_PG_819x117"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=horz_ndg_cut_PG_130x62"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=cart_ndg_cut_PG_819x117"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=gq_pb0.19"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=5tetRef0.31"

# C
# folder_path = output_folder*"C_deck=B_ISO_C_grid=flat_tetra_subwell";name = "flat_tetra_subwell"
folder_path = output_folder*"C_deck=B_ISO_C_grid=tet_zx10-F3_schedule=skipEquil";name = "C_tet_zx10-F3"
SPEcase = basename(folder_path)[1]
# method = "hybrid-avgmpfa"

#
# read_fun = read_MRST_output 
# read_fun = read_jutul_and_convert
read_fun = read_big_jutul_output
model, reservoir_states = read_setup_and_load_states(folder_path, read_fun=read_fun);

fig = plot_reservoir(model[:Reservoir], reservoir_states; 
                     shading= NoShading, edge_color=:grey)
plot_facies = false
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
    # fig.content[18].i_selected = 2 #set scale to all steps, row
    fig.current_axis.x.azimuth.val = -2.21
    fig.current_axis.x.elevation.val = 0.1
    # fig.content[4].selected_indices = (70, 1000) #dont show low values
    # fig.content[1].i_selected = 3 # set variable to rs
end

anim_path = animate(fig;animation_name=name)
crop_video(anim_path; SPEcase = SPEcase)

