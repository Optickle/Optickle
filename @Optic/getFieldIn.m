% returns the index of an input field
%
% n = getFieldIn(obj, inName)
% inName - input name or port number
% n - input field index (0 means not connected)
% np - port number for this input (see getInputPortNum)
%
% Example:
% [n, np] = getFieldIn(optic, 'fr');

function [n, np] = getFieldIn(obj, inName)

  np = getInputPortNum(obj, inName);  % port number
  n = obj.in(np);					            % link number
