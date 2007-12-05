% returns the index of an output field
%
% n = getFieldOut(opt, name, outName)
% name - optic name or serial number
% outName - output name
% n - field index
%
% Example:
% n = getFieldOut(opt, 'PR', 'fr');

function n = getFieldOut(opt, name, outName)

  sn = getSerialNum(opt, name);
  n = getFieldOut(opt.optic{sn}, outName);
