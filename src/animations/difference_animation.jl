using JutulDarcy, Jutul, GLMakie
using ProgressMeter
using VideoIO, ImageTransformations
include("read_mrst_output.jl")

# output_folder = "/media/kristian/HDD/matlab/output/"
output_folder = "/home/kristian/matlab/output/"

# folder_path = output_folder*"B_deck=B_ISO_C_grid=cPEBI_2640x380"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=struct819x117"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=cPEBI_819x117"
folder_path = output_folder*"B_deck=B_ISO_C_grid=horz_ndg_cut_PG_130x62"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=cart_ndg_cut_PG_819x117"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=gq_pb0.19"
# folder_path = output_folder*"B_deck=B_ISO_C_grid=5tetRef0.31"

# C
# folder_path = output_folder*"C_deck=B_ISO_C_grid=struct50x50x50"
# folder_path = output_folder*"C_deck=B_ISO_C_grid=horz_ndg_cut_PG_50x50x50"
# folder_path = output_folder*"C_deck=B_ISO_C_grid=cart_ndg_cut_PG_50x50x50"
# folder_path = output_folder*"C_deck=B_ISO_C_grid=struct100x100x100"
# folder_path = output_folder*"C_deck=B_ISO_C_grid=horz_ndg_cut_PG_100x100x100"
# folder_path = output_folder*"C_deck=B_ISO_C_grid=cart_ndg_cut_PG_100x100x100"

method = "hybrid-avgmpfa"
folder_path_2 = folder_path*"_pdisc="*method

SPEcase = basename(folder_path)[1]
output_path = folder_path*"_output"
## Simulation
case = setup_case_from_mrst(folder_path*".mat");
reservoir_states, _ = read_results(output_path, read_reports=false);
for i in eachindex(reservoir_states)
    reservoir_states[i] = reservoir_states[i][:Reservoir]
end

reservoir_states_1 = readMRSTOutput(folder_path*"/multiphase")
reservoir_states_2 = readMRSTOutput(folder_path_2*"/multiphase")

num_states = length(reservoir_states_1)
difference = Vector{Dict{Symbol, Any}}(undef, num_states)
num_cells = model[:Reservoir].data_domain.representation.nc

for i in eachindex(reservoir_states_1)
    difference[i] = Dict(:Rs=> Vector{Float64}(undef, num_cells))
    difference[i][:Rs] =  vec(reservoir_states_1[i] - reservoir_states_2[i])
end
model = case[1].model;

## Plotting
fig = plot_reservoir(model[:Reservoir], difference)
if SPEcase == 'B'
    fig.content[18].i_selected = 2 #set scale to all steps, row
    fig.content[20].i_selected = 2 #set camera to xz
    # fig.content[1].i_selected = 3 # set variable to rs
elseif SPEcase == 'C'
    fig.content[18].i_selected = 2 #set scale to all steps, row
    fig.current_axis.x.azimuth.val = -2.21
    fig.current_axis.x.elevation.val = 0.1
    fig.content[4].selected_indices = (70, 1000) #dont show low values
    fig.content[1].i_selected = 3 # set variable to rs
end



num_steps = num_states
framerate = 24

## Animation
animation_name = basename(folder_path)
folder = "videos"
fullpath = joinpath(pwd(), folder, animation_name*".mp4")
px_per_unit = 2
compression = 1

p = Progress(num_steps, desc="Recording animation...");
record(fig.content[5].scene, fullpath, 1:num_steps; framerate = framerate, px_per_unit=px_per_unit, compression = compression) do i
    fig.content[3].selected_index = i
    next!(p)
end

## Crop animation

video = VideoIO.load(fullpath);
frame = video[301]
# Define cropping parameters
ny, nx = size(frame)
if SPEcase == 'B'
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
fullpath_cropped = joinpath(dirname(fullpath), "cropped", basename(folder_path)*"_cropped"*filetype)
writer = VideoIO.open_video_out(fullpath_cropped, cropped_frame; framerate=framerate);
p = Progress(length(video);desc="Cropping video...");
for frame in video
    cropped_frame = ImageTransformations.imresize(frame[y:y+height, x:x+width], (height, width))
    VideoIO.write(writer, cropped_frame)
    next!(p)
end
VideoIO.close_video_out!(writer);
