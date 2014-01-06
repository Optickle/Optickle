% Get the full name for this output port for display purposes.
%   The name returned is in the format optic_name->port_name
%
% name = getOutputName(obj, outNum)

function name = getOutputName(obj, outNum)

  name = [obj.name '->' obj.outNames{outNum}{1}];
