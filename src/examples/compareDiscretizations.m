%% Combining consistent discretizations with AD-OO
% We follow example 6.1.2 in the MRST book (see
% examples/1ph/showInconsistentTPFA in the book module). We create a
% skewed grid with two wells where the underlying problem is
% symmetric. An inconsistent discretization of the fluxes may introduce
% asymmetry in the production pattern when injecting a fluid.

% modified from nfvm-examples

clear all
% close all

mrstModule add ad-core mpfa ad-blackoil compositional ad-props mrst-gui nfvm sommer2024


gridname = 'cart';

aspect_ratio = 4; %standard is 4
scaling = 1;
shift = 0;
G = getGrid(gridname, 'aspect_ratio', aspect_ratio, 'scaling', scaling, 'shift', shift);

casename = [gridname, sprintf(', AR=%d, scaling=%.2f, shift=%d', aspect_ratio, scaling, shift)];

grav = false;

if grav
    gravity reset on;
    gravity([0,-9.81]);
    casename = [casename, ', gravity'];
else
    gravity off;
end


% Homogeneous reservoir properties
rock = makeRock(G, 100*milli*darcy, .2);
pv = sum(poreVolume(G, rock));

% interpface = correctHAP(G, findHAP(G, rock));
% plotHAP(G, interpface);axis square;

% Symmetric well pattern 
if any(contains(G.type, 'cartGrid'))
    [ii, jj] = gridLogicalIndices(G);
    c1 = find(ii == ceil(G.cartDims(1) / 2) & jj == G.cartDims(2));
    c2 = find(ii == G.cartDims(1) & jj == 1);
    c3 = find(ii == 1 & jj == 1);
else
    offset = 1e-12;
    xmin = min(G.nodes.coords(:, 1:2));
    xmax = max(G.nodes.coords(:, 1:2));
    c1 = findEnclosingCell(G, [0.5 * (xmin(1) + xmax(1)), xmax(2) - offset]);
    c2 = findEnclosingCell(G, xmin+offset);
    c3 = findEnclosingCell(G, [xmax(1) - offset, xmin(2) + offset]);
end
% Injector + two producers
r = 0.005;
W = [];
W = addWell(W, G, rock, c1, 'comp_i', [1, 0], 'type', 'rate', 'val', pv/year, 'radius', r);
W = addWell(W, G, rock, c2, 'comp_i', [1, 0], 'type', 'bhp', 'val', 50*barsa, 'radius', r);
W = addWell(W, G, rock, c3, 'comp_i', [1, 0], 'type', 'bhp', 'val', 50*barsa, 'radius', r);

plotW(G, W);
%% We can simulate with either immiscible or compositional fluid physics
% The example uses the general simulator framework and as such we can
% easily simulate the same problem with different underlying physics.

fluid = initSimpleADIFluid('cR', 1e-8/barsa, 'rho', [1, 1000, 100]);
useComp = false;

if useComp
    % Compositional, two-component
    [f, info] = getCompositionalFluidCase('verysimple');
    eos = EquationOfStateModel(G, f);
    model = GenericOverallCompositionModel(G, rock, fluid, eos, 'water', false);
    for i = 1:numel(W)
        W(i).components = info.injection;
    end
    z0 = info.initial;
    state0 = initCompositionalState(G, info.pressure, info.temp, [1, 0], z0, eos);
    W(1).val = 100 * W(1).val;
else
    % Immiscible two-phase
    model = GenericBlackOilModel(G, rock, fluid, 'water', true, 'oil', true, 'gas', false);
    state0 = initResSol(G, 1*barsa, [0, 1]);
end
% Schedule
dt = [1; 9; repmat(15, 26, 1)] * day;
schedule = simpleSchedule(dt, 'W', W);

%% Simulate the implicit TPFA base case
disp('TPFA implicit')
[wsTPFA, statesTPFA] = simulateScheduleAD(state0, model, schedule);

%% Simulate implicit MPFA
% The simulator reuses the multipoint transmissibility calculations from
% the MPFA module. We instantiate a special phase potential difference that
% is computed using MPFA instead of the regular two-point difference for
% each face.
disp('MPFA implicit')
model_mpfa = setMPFADiscretization(model);
[wsMPFA, statesMPFA] = simulateScheduleAD(state0, model_mpfa, schedule);
%% Simulate implicit AvgMPFA
disp('AvgMPFA implicit')
ratio = [];
model_avgmpfa = setAvgMPFADiscretization(model, 'myRatio', ratio);
[wsAvgMPFA, statesAvgMPFA] = simulateScheduleAD(state0, model_avgmpfa, schedule);


%% Simulate implicit NTPFA
disp('NTPFA implicit')
ratio = [];

try
    model_ntpfa = setNTPFADiscretization(model, 'myRatio', ratio);
    [wsNTPFA, statesNTPFA] = simulateScheduleAD(state0, model_ntpfa, schedule);
catch msg
    disp("NTPFA failed");
    disp(msg);
    statesNTPFA = cell(2,1);
    for i=1:2
        statesNTPFA{i} = state0;
        statesNTPFA{i}.pressure = statesNTPFA{i}.pressure*nan;
        statesNTPFA{i}.s = statesNTPFA{i}.s.*nan;
    end
end
%% Plot all states together
methods = {'TPFA', 'MPFA', 'avgMPFA', 'NTPFA'};
saturations = {statesTPFA{end}.s(:,1), statesMPFA{end}.s(:,1), statesAvgMPFA{end}.s(:,1), statesNTPFA{end}.s(:,1)};
plotAll(G, saturations, methods, 'End saturation', casename);

saturations = {statesTPFA{1}.s(:,1), statesMPFA{1}.s(:,1), statesAvgMPFA{1}.s(:,1), statesNTPFA{1}.s(:,1)};
plotAll(G, saturations, methods, 'Start saturation', casename);

pressures = {statesTPFA{1}.pressure, statesMPFA{1}.pressure, statesAvgMPFA{1}.pressure, statesNTPFA{1}.pressure};
plotAll(G, pressures, methods, 'Start pressure', casename);

pressures = {statesTPFA{end}.pressure, statesMPFA{end}.pressure, statesAvgMPFA{end}.pressure, statesNTPFA{end}.pressure};
plotAll(G, pressures, methods, 'End pressure', casename);
return
%% Plot Individuals toolbars
plotFinalPressure(G, statesTPFA, 'TPFA');
plotFinalPressure(G, statesAvgMPFA, 'AvgMPFA');
plotFinalPressure(G, statesNTPFA, 'NTPFA');
plotFinalPressure(G, statesMPFA, 'MPFA');
%% Copyright Notice
%
% <html>
% <p><font size="-1">
% Copyright 2009-2023 SINTEF Digital, Mathematics & Cybernetics.
% </font></p>
% <p><font size="-1">
% This file is part of The MATLAB Reservoir Simulation Toolbox (MRST).
% </font></p>
% <p><font size="-1">
% MRST is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% </font></p>
% <p><font size="-1">
% MRST is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% </font></p>
% <p><font size="-1">
% You should have received a copy of the GNU General Public License
% along with MRST.  If not, see
% <a href="http://www.gnu.org/licenses/">http://www.gnu.org/licenses</a>.
% </font></p>
% </html>
