function G = getGrid(gridname, varargin)
opt = struct('aspectratio', 2);
opt = merge_options(opt, varargin{:});

if contains(gridname, 'skew') || contains(gridname, 'twist') || contains(gridname, 'cart')
    % Without twisting the methods should yield the same results
    dims = [41, 20];
    G = cartGrid(dims, [2, 1]);
    
    if contains(gridname, 'skew')
        makeSkew = @(c) c(:, 1) + .4 * (1 - (c(:, 1) - 1).^2) .* (1 - c(:, 2));
        G.nodes.coords(:, 1) = 2 * makeSkew(G.nodes.coords);
        % G.nodes.coords(:, 1) = G.nodes.coords(:, 1) * 1000;
        % G.nodes.coords(:, 2) = G.nodes.coords(:, 2) * 1000;
    end

    G.nodes.coords(:, 1) = G.nodes.coords(:, 1) - 1;
    G.nodes.coords(:, 2) = G.nodes.coords(:, 2) - 0.5;
    
    G.nodes.coords(:,1) = G.nodes.coords(:,1)*opt.aspectratio/2;
    
    if contains(gridname, 'twist')
        G = twister(G);
    end
    if contains(gridname, 'simplices')
        G = triangleGrid(G.nodes.coords);
    end
end

% if contains(gridname, 'superflat')
%     G.nodes.coords(:,1) = G.nodes.coords(:,1)*40;
% end

G = computeGeometry(G);
end