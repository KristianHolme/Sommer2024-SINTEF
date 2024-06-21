function model = setCombinedPhasePotentialDifference(model)
if ~isprop(model, 'FlowDiscretization') || isempty(model.FlowDiscretization)
    model = model.setupStateFunctionGroupings();
end
fd = model.FlowDiscretization;
fd = fd.setStateFunction('GravityPotential', GravityPotential(model));
ppd = CombinedPhasePotentialDifference(model);
pg = fd.getStateFunction('PressureGradient');
grad = pg.Grad;
ppd.grad = grad;
fd = fd.setStateFunction('PhasePotentialDifference',ppd);
model.FlowDiscretization = fd;
end