% Get the full name for this input port for display purposes.
%   The name returned is in the format optic_name<-port_name
%
% name = getInputName(obj, inNum)

function name = getInputName(obj, inNum)

  name = [obj.name '<-' obj.inNames{inNum}{1}];
