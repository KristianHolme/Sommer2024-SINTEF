function plotAll(G, states, methods, statename, casename, varargin)
opt = struct('plotContour', false);
opt = merge_options(opt, varargin{:});
figure;
T = tiledlayout(2,2);

maxval = -Inf;
minval = Inf;
for i = 1:numel(states)
    maxval = max(maxval, max(states{i}));
    minval = min(minval, min(states{i}));
end
%plot states
for i = 1:numel(states)
    nexttile(i);
    plotCellData(G, states{i}, 'edgealpha', double(~opt.plotContour));
    clim([minval, maxval]); % Set color limits for consistency
    axis tight;
    if opt.plotContour
        hold on;
        if isfield(G, 'cartDims')
            contour(reshape(G.cells.centroids(:, 1), G.cartDims), ...
                    reshape(G.cells.centroids(:, 2), G.cartDims), ...
                    reshape(states{i}, G.cartDims), ...
                    'linewidth', 1, 'color', 'k');
        else
            unstructuredContour(G, states{i});
        end
        hold off;
    end
    title(methods{i});
end

%main title
title(T, [statename,', ', casename]);

h = colorbar;
h.Layout.Tile = 'east'; % Position the colorbar on the east side

savename = replace(statename, ' ', '_');
savename = replace(savename, ',', '_');
savepath = fullfile("plots/threeWellTest",casename, [savename, '.png']);
[savedir, ~] = fileparts(savepath);
if ~exist(savedir, 'dir')
    % If it does not exist, create it
    mkdir(savedir);
end
saveas(T, savepath);
end
