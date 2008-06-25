% n = getSerialNum(opt, name)
%   returns the serial number of an optic,
%   given the optic's name or serial number

function n = getSerialNum(opt, name)

  Nopt = opt.Noptic;				% number of optics

  % if name is really a string, try to match it
  if ischar(name)
    n = 0;
    for m = 1:Nopt
      if strcmp(opt.optic{m}.name, name)
        n = m;
        break
      end
    end
    
    if n == 0
      error('No optic named "%s" found.', name)
    end
  elseif isnumeric(name)
    n = name;
    
    % check serial number range
    if n < 1
      error('serial number out of range (%d < 1)', n)
    end
    
    if n > Nopt
      error('serial number out of range (%d > %d)', n, Nopt)
    end
  else
    error('Invalid argument of type %s', class(name));
  end
