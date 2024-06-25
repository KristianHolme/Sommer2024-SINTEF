function faceBlocks = faceBlocksFromIndicator(G, varargin)
opt = struct('faceErrorIndicator', [], ...
    'cellErrorindicator', []);
opt = merge_options(opt, varargin{:});

faceBlocks = cell(2,1);

if ~isempty(opt.faceErrorIndicator)
    tol = 1e-22;
    highErrorFaces = opt.faceErrorIndicator > tol;
    faceBlocks{2} = find(highErrorFaces);
    faceBlocks{1} = setdiff(1:G.faces.num, faceBlocks{2});
elseif ~isempty(opt.cellErrorIndicator)
    
    
end