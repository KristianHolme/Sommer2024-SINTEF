function [faceBlocks, cellBlocks] = getFaceBlocksFromIndicator(G, varargin)
% uses the static K-orthogonality error indicator to determine which faces
% has the highest error. Made for use in hybrid discretizations.
opt = struct('faceError', [], ...
    'cellError', [], ...
    'rock', [], ...
    'percentConsistent', 0, ...
    'layers', 0);
opt = merge_options(opt, varargin{:});

cellBlocks = cell(1,2);
if ~isempty(opt.faceError)
    tol = 1e-20; %ok?
    faceBlocks = cell(1,2);

    highErrorFaces = opt.faceError > tol;

    faceBlocks{2} = find(highErrorFaces); %consistent method faces
    faceBlocks{1} = setdiff(1:G.faces.num, faceBlocks{2});% tpfa faces
elseif ~isempty(opt.cellError)
    tol = 1e-18; %ok?
    highErrorCells = opt.cellError > tol;

    if opt.percentConsistent ~= 0
        tol = prctile(opt.cellError(highErrorCells), 100 - opt.percentConsistent);
        highErrorCells = opt.cellError > tol;
    end

    cellBlocks{2} = find(highErrorCells);
    %for multiple layers
    if opt.layers ~= 0
        cellBlocks{2} = findCellNeighbors(G, cellBlocks{2}, opt.layers);
    end
    cellBlocks{1}= setdiff(1:G.cells.num, cellBlocks{2});

    faceBlocks = faceBlocksFromCellBlocks(G, cellBlocks);
else
    %compute error
    tables = setupTables(G);
    assert(~isempty(opt.rock), "Neither error nor rock supplied!")
    [~, ~, fwerr] = computeOrthError(G, rock, tables);
    faceBlocks = getFaceBlocksFromIndicator(G, 'cellError', fwerr);
end

end

