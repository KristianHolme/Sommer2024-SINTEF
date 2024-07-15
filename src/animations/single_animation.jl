using JutulDarcy, Jutul, GLMakie
using ProgressMeter
using VideoIO, ImageTransformations
include("read_mrst_output.jl")
include("animate_and_crop.jl")
include("read_big_output.jl")
include("utils.jl")

# output_folder = "/media/kristian/HDD/matlab/output/"
output_folder = "/home/kristian/matlab/output/"

# folder_path = output_folder*"A_deck=RS_grid=5tetRef10_pdisc=ntpfa"

# folder_path = output_folder*"B_deck=B_ISO_C_grid=cPEBI_2640x380"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=struct819x117"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=cPEBI_819x117"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=horz_ndg_cut_PG_819x117"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=horz_ndg_cut_PG_130x62"
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
folder_path = output_folder*"C_deck=B_ISO_C_grid=flat_tetra_subwell"

method = "hybrid-avgmpfa"

name = "C_flat_tetra_subwell"


SPEcase = basename(folder_path)[1]
output_path = folder_path*"_output"
## Mock Simulation
case = setup_case_from_mrst(folder_path*".mat");
model = case[1].model;
num_cells = model[:Reservoir].data_domain.representation.nc
reservoir_states = readMRSTOutput(folder_path*"/multiphase")
num_states = length(reservoir_states)
states1 = Vector{Dict{Symbol, Any}}(undef, num_states)
for i in eachindex(reservoir_states)
    states1[i] = Dict(:Rs=> Vector{Float64}(undef, num_cells))

    states1[i][:Rs] =  vec(reservoir_states[i])
end
# reservoir_states = read_big_output(output_path) #for large simulations

#for sims run in jutul
# reservoir_states, _ = read_results(output_path, read_reports=false); 
# for i in eachindex(reservoir_states)
#     reservoir_states[i] = reservoir_states[i][:Reservoir]
# end

#for sims in mrst

chosen_states = states1
fig = plot_reservoir(model[:Reservoir], chosen_states; 
                    shading= NoShading, edge_color=:grey)
plot_facies = true
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

anim_path = animate(fig;animation_name=name, num_steps = 301)
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