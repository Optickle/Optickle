% returns the serial number of a probe,
% given the probes's name or serial number
%
% n = getProbeNum(opt, name)

function n = getProbeNum(opt, name)

  Nprb = opt.Nprobe;				% number of probes

  % if name is really a string, try to match it
  if ischar(name)
    n = 0;
    for m = 1:Nprb
      if strcmp(opt.probe(m).name, name)
        n = m;
        break
      end
    end
    
    if n == 0
      error('No probe named "%s" found.', name)
    end
  elseif isnumeric(name)
    n = name;
    
    % check serial number range
    if n < 1
      error('serial number out of range (%d < 1)', n)
    end
    
    if n > Nprb
      error('serial number out of range (%d > %d)', n, Nprb)
    end
  else
    error('Invalid argument of type %s', class(name));
  end
