% n = getProbeNum(opt, name)
%   returns the serial number of a probe,
%   given the probes's name or serial number
%
% see also getProbeName

function nOut = getProbeNum(opt, name)

  Nprb = opt.Nprobe;				% number of probes

  % force cell array input
  name = name2cell(name);
  
  % loop on all names
  nOut = zeros(size(name));
  for nn = 1:numel(nOut)
  
    % if name is really a string, try to match it
    if ischar(name{nn})
      n = 0;
      for m = 1:Nprb
        if strcmp(opt.probe(m).name, name{nn})
          n = m;
          break
        end
      end
      
      if n == 0
        error('No probe named "%s" found.', name{nn})
      end
    elseif isnumeric(name{nn})
      n = name{nn};
      
      % check serial number range
      if n < 1
        error('serial number out of range (%d < 1)', n)
      end
      
      if n > Nprb
        error('serial number out of range (%d > %d)', n, Nprb)
      end
    else
      error('Invalid argument of type %s', class(name{nn}));
    end
    
    % store result
    nOut(nn) = n;
  end
end
