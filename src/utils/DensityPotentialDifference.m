classdef DensityPotentialDifference < StateFunction
    
    properties
        weight = []; % Optional weighting matrix for gravity
        grad
    end
    
    methods
        function gp = DensityPotentialDifference(grad, varargin)
            gp@StateFunction(varargin{:});
            gp = gp.dependsOn('Density', 'PVTPropertyFunctions');
            gp.grad = grad;
            gp.label = '\nabla \rho g z';
        end
        function drho_gz = evaluateOnDomain(prop, model, state)
            act = model.getActivePhases();
            nph = sum(act);
            
            drho_gz = cell(1, nph);
            nf = size(model.operators.N, 1);
            avg = model.operators.faceAvg;
            if norm(model.gravity) > 0 && nf > 0
                 assert(isfield(model.G, 'cells'), 'Missing cell field on grid');
                 assert(isfield(model.G.cells, 'centroids'),...
                'Missing centroids field on grid. Consider using computeGeometry first.');

                g = model.getGravityVector();
                gxyz = model.G.cells.centroids * g';

                rho = prop.getEvaluatedExternals(model, state, 'Density');
                rho = expandMatrixToCell(rho);
                for i = 1:nph

                    rhoph = rho{i};

                    drho_gz{i} = -prop.grad(rhoph).*avg(gxyz); %negative sign
                end
            else
                [drho_gz{:}] = deal(zeros(nf, 1));
            end
            %dont know what weight should do, just left as is
            w = prop.weight;
            if ~isempty(w)
                for i = 1:numel(drho_gz)
                    drho_gz{i} = w*drho_gz{i};
                end
            end
        end
    end
end

%{
Copyright 2009-2023 SINTEF Digital, Mathematics & Cybernetics.

This file is part of The MATLAB Reservoir Simulation Toolbox (MRST).

MRST is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

MRST is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with MRST.  If not, see <http://www.gnu.org/licenses/>.
%}
