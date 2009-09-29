% returns an input port number, given the port's name or number
%
% n = getInputPortNum(obj, portName)
%
% Example:
% n = getInputPortNum(optic, 'fr')

function n = getInputPortNum(obj, name)

  if ischar(name)
    % ==== name is a string, try to match it
    m = [];
    for n = 1:obj.Nin
      m = strmatch(name, obj.inNames{n}, 'exact');
      if ~isempty(m)
        break
      end
    end
    
    if isempty(m)
      error('Invalid input name "%s" for optic "%s".', name, obj.name)
    end
  elseif isnumeric(name)
    % ==== name is an index, check it
    n = name;
    if n < 1
      error('Input out of range (%d < 1) for optic "%s".', n, obj.name)
    end
    
    if n > obj.Nin
      error('Input out of range (%d > %d) for optic "%s".', n, obj.Nin, obj.name)
    end
  else
    % ==== name is not a number or a string...
    error('Invalid argument of type %s', class(name));
  end
  
end
