function AR = plotAspectRatio(G, varargin)
opt = struct('name', 'G');
opt = merge_options(opt, varargin{:});

AR = nan(G.cells.num, 2);
[n, pos] = gridCellNodes(G, 1:G.cells.num);
for ic = 1:G.cells.num
    nodes = n(pos(ic):pos(ic+1)-1);
    nodeCoords = G.nodes.coords(nodes,:);
    range = nan(3,1);
    for idir = 1:3
        range(idir) = max(nodeCoords(:,idir)) - min(nodeCoords(:,idir));
    end
    range = range ./ range(3);
    AR(ic,:) = range(1:2);
end
% hist3(AR);
x = AR(:,1);
y = AR(:,2);
xEdges = linspace(min(x), max(x), 21);
yEdges = linspace(min(y), max(y), 21);

% Create a 2D histogram
[N, xEdges, yEdges] = histcounts2(x, y, xEdges, yEdges);
N = log10(N+1);
% Create a heatmap
heatmap(xEdges(1:end-1), yEdges(1:end-1), N', 'Colormap', parula, 'ColorbarVisible', 'on');

% Label axes
xlabel('dx:dz');
ylabel('dy:dz');
title(['Aspect Ratios for ', opt.name, ', log10(freq)']);
% tightfig();
saveas(gcf, fullfile('./plots/aspectratios', opt.name), 'png');
end




    