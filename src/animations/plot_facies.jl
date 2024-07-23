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