function plotW(G, W)
injcellsIx = [W.sign] == 1;
wellCells = [W.cells];
injcells = wellCells(injcellsIx);
prodcells = wellCells(~injcellsIx);

plotGrid(G, 'facealpha', 0);
plotGrid(G, injcells, 'facecolor', 'r');
plotGrid(G, prodcells, 'facecolor', 'b');
end
