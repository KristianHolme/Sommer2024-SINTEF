function plotAll(G, states, methods, statename, casename, varargin)
opt = struct();
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
    plotCellData(G, states{i});
    clim([minval, maxval]); % Set color limits for consistency
    axis tight;
    title(methods{i});
end

%main title
title(T, [statename,', ', casename]);

h = colorbar;
h.Layout.Tile = 'east'; % Position the colorbar on the east side

savename = replace(statename, ' ', '_');
savename = replace(savename, ',', '_');
savepath = fullfile("plots/",casename, [savename, '.png']);
[savedir, ~] = fileparts(savepath);
if ~exist(savedir, 'dir')
    % If it does not exist, create it
    mkdir(savedir);
end
saveas(T, savepath);
end
