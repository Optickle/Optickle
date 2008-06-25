% n = getFieldProbed(opt, name)
%   returns the index of a field seen by some probe
%
% name - probe name or serial number
% n - field index
%
% see also getFieldIn, getFieldOut, getLinkNum
%
% Example:
% n = getFieldProbed(opt, 'REFL DC');

function n = getFieldProbed(opt, name)

  sn = getProbeNum(opt, name);
  n = opt.probe(sn).nField;
