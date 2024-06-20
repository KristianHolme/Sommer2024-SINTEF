classdef CombinedPhasePotentialDifference < StateFunction
    % The potential difference over each interface, for each phase. 
    properties
        hasGravity; % Is there gravity?
        grad
    end
    
    methods
        function gp = CombinedPhasePotentialDifference(model, varargin)
            gp@StateFunction(model, varargin{:});
            gp = gp.dependsOn('PhasePressures', 'PVTPropertyFunctions');
            gp = gp.dependsOn('pressure', 'state');
            gp.hasGravity = norm(model.getGravityVector(), inf) > 0;
            if gp.hasGravity
                gp = gp.dependsOn('GravityPotential');
            end
            gp.label = '\Theta_\alpha';
        end
        function v = evaluateOnDomain(prop, model, state)
            act = model.getActivePhases();
            nph = sum(act);
            
            potential = cell(1, nph);
            if model.FlowPropertyFunctions.CapillaryPressure.pcPresent(model)
                % We have different phase pressures, call gradient once for
                % each phase
                pressurePotential = prop.getEvaluatedExternals(model, state, 'PhasePressures');
            else
                % There is no capillary pressure and a single gradient for
                % the unique pressure is sufficient
                p = model.getProp(state, 'pressure');
                pressurePotential = cell(1, nph);
                for i = 1:nph
                    pressurePotential{i} = p;
                end
            end
            if prop.hasGravity
                rhogz = prop.getEvaluatedDependencies(state, 'GravityPotential');
                for i = 1:nph
                    potential{i} = pressurePotential{i} + rhogz{i};
                end
            else
                potential = pressurePotential;
            end
            v = cell(1, nph);
            for i = 1:nph
                if min(potential{i})<0
                    warning("negative phase potential!");
                end
                v{i} = prop.grad(potential{i});
            end
            %testing
            rhogdz = model.getProp(state, 'GravityPotentialDifference');
            dp = model.getProp(state, 'PressureGradient');
            for i = 1:numel(dp)
                ppd_org{i} = dp{i} + rhogdz{i};
                ppd_sep_diff{i} = prop.grad(pressurePotential{i}) + prop.grad(rhogz{i}) - v{i};
                gpdiff{i} = prop.grad(rhogz{i}) - rhogdz{i};
                dpdiff{i} = prop.grad(pressurePotential{i}) - dp{i};
            end
        end
    end
end