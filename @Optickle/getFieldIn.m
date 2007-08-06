% returns the index of an input field
%
% n = getFieldIn(opt, name, inName)
% name - optic name or serial number
% inName - input name
% n - field index
%
% Example:
% n = getFieldIn(opt, 'PR', 'fr');

function n = getFieldIn(opt, name, inName)

  sn = getSerialNum(opt, name);
  n = getFieldIn(opt.optic{sn}, inName);
