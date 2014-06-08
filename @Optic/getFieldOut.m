% returns the index of an output field
%
% n = getFieldOut(obj, outName)
% outName - output name or port number
% n - output field index (0 means not connected)
% np - port number for this output (see getOutputPortNum)
%
% Example:
% [n, np] = getFieldOut(optic, 'fr');

function [n, np] = getFieldOut(obj, outName)

  np = getOutputPortNum(obj, outName);  % port number
  n = obj.out(np);					            % link number
