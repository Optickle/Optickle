% returns the index of a field seen by some probe
%
% n = getFieldProbed(opt, name)
% name - probe name or serial number
% n - field index
%
% Example:
% n = getFieldProbed(opt, 'REFL DC');

function n = getFieldProbed(opt, name)

  sn = getProbeNum(opt, name);
  n = opt.probe(sn).nField;
