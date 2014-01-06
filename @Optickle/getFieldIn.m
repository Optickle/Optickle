% n = getFieldIn(opt, name, inName)
%   returns the index of an input field
%
% name - optic name or serial number, or array of names/numbers
% inName - input name, or array of names/numbers
% n - field index
%
% see also getFieldOut, getFieldProbed, getLinkNum
%
% Example:
% nIX = getFieldIn(optFP, 'IX', 'fr');
% nEX = getFieldIn(optFP, 'EX', 'fr');
% nBoth = getFieldIn(optFP, {'IX', 'EX'}, 'fr');

function n = getFieldIn(opt, name, inName)

  sn = getSerialNum(opt, name);

  % force inName to cell array
  inName = name2cell(inName);
    
  % deal with multiple optics, ports, or both
  if numel(sn) == 1
    % just one optic... loop over port names
    n = zeros(size(inName));
    for m = 1:numel(inName)
      n(m) = getFieldIn(opt.optic{sn}, inName{m});
    end
  else
    % multiple optics... check number of port names
    n = zeros(size(sn));
    
    if numel(inName) == 1
      % just one port name... strange, but ok
      for m = 1:numel(sn)
          n(m) = getFieldIn(opt.optic{sn(m)}, inName{1});
      end
    elseif numel(sn) == numel(inName)
      % multiple optics and multiple ports
      for m = 1:numel(sn)
          n(m) = getFieldIn(opt.optic{sn(m)}, inName{m});
      end
    else
      error('Number of optic names and port names must match.')
    end
  end
end
