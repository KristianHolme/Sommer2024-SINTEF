function faceBlocks = getFaceBlocksFromIndicator(G, varargin)
% uses the static K-orthogonality error indicator to determine which faces
% has the highest error. Made for use in hybrid discretizations.
opt = struct('faceError', [], ...
    'cellError', [], ...
    'rock', []);
opt = merge_options(opt, varargin{:});


if ~isempty(opt.faceError)
    tol = 1e-20; %ok?
    faceBlocks = cell(1,2);

    highErrorFaces = opt.faceError > tol;

    faceBlocks{2} = find(highErrorFaces); %consistent method faces
    faceBlocks{1} = setdiff(1:G.faces.num, faceBlocks{2});% tpfa faces
elseif ~isempty(opt.cellError)
    tol = 1e-18; %ok?
    cellBlocks = cell(1,2);

    highErrorCells = opt.cellError > tol;

    cellBlocks{2} = find(highErrorCells);
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

