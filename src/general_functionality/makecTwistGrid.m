function G = makecTwistGrid(nx, ny, nz, varargin)
opt = struct('tets', false, ...
    'twist', true,...%for optionally making cartesian grids
    'tag', '');
opt = merge_options(opt, varargin{:});
if contains(opt.tag, 'even')
    x1 = 100;
    x2 = 200;

    y1 = 100;
    y2 = 200;
    
    z1 = 100;
    z2 = 200;
elseif contains(opt.tag, 'flat')
    x1 = 0;
    x2 = 100;

    y1 = 0;
    y2 = 100;
    
    z1 = 0;
    z2 = 1;
else
    x1 = 0.2585031375e7;
    x2 = 0.2605031375e7;
    
    y1 = 3.3538168e7;
    y2 = 3.3558168e7;
    
    z1 = 0.000287834521484e7;
    z2 = 0.000308204256421e7;
end

G = cartGrid([nx, ny, nz], [x2-x1, y2-y1, z2-z1]);
if opt.twist
    G = twister(G);
end
G.nodes.coords = G.nodes.coords + [x1, y1, z1];
if opt.tets
    G = tetrahedralGrid(G.nodes.coords);
end
G = mcomputeGeometry(G);
end