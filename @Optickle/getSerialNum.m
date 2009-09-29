% n = getSerialNum(opt, name)
%   returns the serial number of an optic,
%   given the optic's name or serial number

function nOut = getSerialNum(opt, name)

  Nopt = opt.Noptic;				% number of optics

  % force cell array input
  name = name2cell(name);
  
  % loop on all names
  nOut = zeros(size(name));
  for nn = 1:numel(nOut)
  
    % if name is really a string, try to match it
    if ischar(name{nn})
      n = 0;
      for m = 1:Nopt
        if strcmp(opt.optic{m}.name, name{nn})
          n = m;
          break
        end
      end
      
      if n == 0
        error('No optic named "%s" found.', name{nn})
      end
    elseif isnumeric(name{nn})
      n = name{nn};
      
      % check serial number range
      if n < 1
        error('serial number out of range (%d < 1)', n)
      end
      
      if n > Nopt
        error('serial number out of range (%d > %d)', n, Nopt)
      end
    else
      error('Invalid name argument of type %s', class(name{nn}));
    end
    
    % store result
    nOut(nn) = n;
  end
  
end
