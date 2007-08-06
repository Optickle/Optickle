% returns the index of an output field
%
% n = getFieldIn(opt, name, inName)
% name - optic name or serial number
% outName - output name
% n - field index
%
% Example:
% n = getFieldIn(opt, 'PR', 'fr');

function n = getFieldOut(opt, name, outName)

  sn = getSerialNum(opt, name);
  n = getFieldOut(opt.optic{sn}, outName);
