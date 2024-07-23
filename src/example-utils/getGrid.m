function G = getGrid(gridname, varargin)
opt = struct('aspect_ratio', 2, ...
    'scaling', 1, ...
    'shift', 0);
opt = merge_options(opt, varargin{:});

if contains(gridname, 'skew') || contains(gridname, 'twist') || contains(gridname, 'cart')
    G = setupCartish(gridname, opt);
    if contains(gridname, 'simplices')
        G = triangleGrid(G.nodes.coords);
    end
elseif contains(gridname, 'rand') 
   G = triGrid(gridname, opt);
elseif contains(gridname, 'gmshTri')
    if contains(gridname, '-M')
        G = load("src/gmshGrids/gmshRectangle2.mat").G;
    else
        G = load("src/gmshGrids/gmshrectangle.mat").G;
    end
    if contains(gridname, 'pebi')
        G = pebi(G);
    end
end
G.nodes.coords(:, 1) = G.nodes.coords(:, 1) * opt.scaling + opt.shift;
G.nodes.coords(:, 2) = G.nodes.coords(:, 2) * opt.scaling + opt.shift;

G.nodes.coords(:,1) = G.nodes.coords(:,1)*(opt.aspect_ratio/4);

G = computeGeometry(G);
end

function G = setupCartish(gridname, opt)
% Without twisting the methods should yield the same results
dims = [41, 20];
if endsWith(gridname, '-M')
    dims = dims*4;
end
G = cartGrid(dims, [2, 1]);

if contains(gridname, 'skew')
    makeSkew = @(c) c(:, 1) + .4 * (1 - (c(:, 1) - 1).^2) .* (1 - c(:, 2));
    G.nodes.coords(:, 1) = 2 * makeSkew(G.nodes.coords);
else
    G.nodes.coords(:, 1) = 2 *  G.nodes.coords(:, 1);
end

if contains(gridname, 'twist')
    G = twister(G);
end
if contains(gridname, 'simplices')
    G = triangleGrid(G.nodes.coords);
end
% G.nodes.coords(:, 1) = G.nodes.coords(:, 1) - 1;
% G.nodes.coords(:, 2) = G.nodes.coords(:, 2) - 0.5;


end
function G = triGrid(gridname, opt)
x1 = 0;
    x2 = 4;
    y1 = 0;
    y2 = 1;
    corners = [x1,y1;
               x2, y1;
               x2,y2;
               x1, y2];

    bdry = interpolateBoundaryPoints(corners, 10);

    num_pts =  400;
    if endsWith(gridname, '-M')
        num_pts = num_pts*4;
    end
    
    if contains(gridname, 'rand')
        pts_x = x1 + (x2-x1)*rand(num_pts,1);
        pts_y = y1 + (y2-y1)*rand(num_pts,1);
        
    end
    pts = [pts_x,pts_y];
    all_points = [bdry;
                    pts];
    if contains(gridname, 'pebi')
        G = clippedPebi2D(all_points, corners);
    else
        G = triangleGrid(all_points);
    end
end
function boundaryPoints = interpolateBoundaryPoints(vertices, numPointsPerSide)
    % vertices: 4x2 matrix of the quadrilateral vertices [x1, y1; x2, y2; x3, y3; x4, y4]
    % numPointsPerSide: number of points to generate per side (including the vertices)
    % boundaryPoints: generated points along the boundary of the quadrilateral

    % Number of points per segment (excluding the end point)
    numPoints = numPointsPerSide - 1;

    % Preallocate the array for the boundary points
    boundaryPoints = zeros(4 * numPoints, 2);

    % Loop to generate interpolated points on each side
    index = 1;
    for k = 1:4
        % Define the start and end vertices of the current side
        startVertex = vertices(k, :);
        endVertex = vertices(mod(k, 4) + 1, :);

        % Interpolate points along the current side
        for i = 0:numPoints-1
            t = i / numPoints;
            boundaryPoints(index, :) = (1 - t) * startVertex + t * endVertex;
            index = index + 1;
        end
    end
end

