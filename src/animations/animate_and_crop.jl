## Animation
function animate(fig; animation_name="anim", folder = "videos",
    num_steps=301,
    framerate=24,
    pixels_per_unit = 2,
    compression = 1)
    fullpath = joinpath(pwd(), folder, animation_name*".mp4")

    p = Progress(num_steps, desc="Recording animation...");
    record(fig.content[5].scene, fullpath, 1:num_steps; framerate = framerate, px_per_unit=pixels_per_unit, compression = compression) do i
        fig.content[3].selected_index = i
        next!(p)
    end
    return fullpath
end

## Crop animation
function crop_video(path;num_steps=301,
    framerate = 24,
    SPEcase = 'B')
    video = VideoIO.load(path);
    frame = video[num_steps]
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
