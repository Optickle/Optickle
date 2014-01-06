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

  % get probe numbers
  sn = getProbeNum(opt, name);
  
  % convert to link numbers
  n = zeros(size(sn));
  for nn = 1:numel(sn)
    n(nn) = opt.probe(sn(nn)).nField;
  end
end
