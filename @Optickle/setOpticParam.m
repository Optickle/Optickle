% Change a parameter of an optic in the model
%
% [opt] = setOpticParam(opt, name, param, value)
%
% This function reaches into the Optickle model to change a field of one of
% the component objects.  It is useful when you want to vary a parameter in
% the model without reconstructing the entire model.
%
% Example:
%
% % Turn off RF sideband
% opt = setOpticParam(opt, 'Mod1', 'aMod', 0);

function op = setOpticParam(op, name, param, value)

% Find the object to be modified
sn = getSerialNum(op, name);
optic = op.optic{sn};

% Modify it
optic = set(optic, param, value);

% Put it back in place
op.optic{sn} = optic;

