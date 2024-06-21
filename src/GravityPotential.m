classdef GravityPotential < StateFunction
    % Difference in phase potential over a face due to gravity
    properties
        saturationWeighting = false; % Use saturation-weighted density for average
        weight = []; % Optional weighting matrix for gravity
    end
    
    methods
        function gp = GravityPotential(varargin)
            gp@StateFunction(varargin{:});
            % gp = gp.dependsOn('Density', 'PVTPropertyFunctions');
            if gp.saturationWeighting
                gp = gp.dependsOn('s', 'state');
            end
            gp.label = 'g z';
        end
        function gRhoXYZ = evaluateOnDomain(prop, model, state)
            act = model.getActivePhases();
            nph = sum(act);
            
            gRhoXYZ = cell(1, nph);
            nf = size(model.operators.N, 1);
            if norm(model.gravity) > 0 && nf > 0
                 assert(isfield(model.G, 'cells'), 'Missing cell field on grid');
                 assert(isfield(model.G.cells, 'centroids'),...
                'Missing centroids field on grid. Consider using computeGeometry first.');

                g = model.getGravityVector();
                gxyz = model.G.cells.centroids * g';

                % nm = model.getPhaseNames();
                % rho = prop.getEvaluatedExternals(model, state, 'Density');
                % rho = expandMatrixToCell(rho);
                for i = 1:nph
                    % Aner ikke om dette blir riktig, har bare fjernet
                    % faceavg-funksjonen
                    % if prop.saturationWeighting
                    %     s = model.getProp(state, ['s', nm(i)]);
                    %     rhoph = s.*rho{i}./max(s, 1e-8);
                    % else
                    %     rhoph = rho{i};
                    % end
                    % gRhoXYZ{i} = -rhoph.*gxyz; %negative sign
                    gRhoXYZ{i} = gxyz; %removed rho, changed sign
                end
            else
                [gRhoXYZ{:}] = deal(zeros(nf, 1));
            end
            %dont know what weight should do, just left as is
            w = prop.weight;
            if ~isempty(w)
                for i = 1:numel(gRhoXYZ)
                    gRhoXYZ{i} = w*gRhoXYZ{i};
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
