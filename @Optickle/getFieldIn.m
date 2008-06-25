% n = getFieldIn(opt, name, inName)
%   returns the index of an input field
%
% name - optic name or serial number
% inName - input name
% n - field index
%
% see also getFieldOut, getFieldProbed, getLinkNum
%
% Example:
% n = getFieldIn(optFP, 'IX', 'fr');

function n = getFieldIn(opt, name, inName)

  sn = getSerialNum(opt, name);
  n = getFieldIn(opt.optic{sn}, inName);
