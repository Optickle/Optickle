% returns an output port number, given the port's name or number
%
% n = getOutputPortNum(obj, portName)
%
% Example:
% n = getOutputPortNum(optic, 'fr')

function n = getOutputPortNum(obj, name)

  if ischar(name)
    % ==== name is a string, try to match it
    m = [];
    for n = 1:obj.Nout
      m = strmatch(name, obj.outNames{n}, 'exact');
      if ~isempty(m)
        break
      end
    end
    
    if isempty(m)
      error('Invalid output name "%s" for optic "%s".', name, obj.name)
    end
  elseif isnumeric(name)
    % ==== name is an index, check it
    n = name;
    if n < 1
      error('Output out of range (%d < 1) for optic "%s".', n, obj.name)
    end
    
    if n > obj.Nout
      error('Output out of range (%d > %d) for optic "%s".', n, obj.Nout, obj.name)
    end
  else
    % ==== name is not a number or a string...
    error('Invalid argument of type %s', class(name));
  end
