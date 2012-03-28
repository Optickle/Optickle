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

  % force outName to cell array
  outName = name2cell(outName);

  % deal with multiple optics, ports, or both
  if numel(sn) == 1
    % just one optic... loop over port names
    n = zeros(size(outName));
    for m = 1:numel(outName)
      n(m) = getFieldOut(opt.optic{sn}, outName{m});
    end
  else
    % multiple optics... check number of port names
    n = zeros(size(sn));
    
    if numel(outName) == 1
      % just one port name... strange, but ok
      for m = 1:numel(sn)
          n(m) = getFieldOut(opt.optic{sn(m)}, outName{1});
      end
    elseif numel(sn) == numel(outName)
      % multiple optics and multiple ports
      for m = 1:numel(sn)
          n(m) = getFieldOut(opt.optic{sn(m)}, outName{m});
      end
    else
      error('Number of optic names and port names must match.')
    end
  end
end
