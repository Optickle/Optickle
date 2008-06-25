% n = getFieldOut(opt, name, outName)
%   returns the index of an output field
%
% name - optic name or serial number
% outName - output name
% n - field index
%
% NOTE: Fields are evaluated at the end of each link, which
% is also the input to the next optic.  Thus, getFieldOut
% returns the index of a field which is NOT at the specified
% output (since there is no field evaluated there), but rather
% at the input to the optic at the end of the corresponding
% link.  Where possible, use getFieldIn to improve clarity.
%
% see also getFieldIn, getFieldProbed, getLinkNum
%
% Example:
% n = getFieldOut(optFP, 'EX', 'fr');

function n = getFieldOut(opt, name, outName)

  sn = getSerialNum(opt, name);
  n = getFieldOut(opt.optic{sn}, outName);
