% returns an input drive number, given the drives's name or number
%
% n = getDriveNum(obj, portName)
%
% Example:
% n = getDriveNum(optic, 'fr')

function n = getDriveNum(obj, name)

  if ischar(name)
    % ==== name is a string, try to match it
    m = [];
    for n = 1:obj.Ndrive
      m = strmatch(name, obj.driveNames{n}, 'exact');
      if ~isempty(m)
        break
      end
    end
    
    if isempty(m)
      error('Invalid drive name "%s" for optic "%s".', name, obj.name)
    end
  elseif isnumeric(name)
    % ==== name is an index, check it
    n = name;
    if n < 1
      error('Drive out of range (%d < 1) for optic "%s".', n, obj.name)
    end
    
    if n > obj.Ndrive
      error('Drive out of range (%d > %d) for optic "%s".', ...
        n, obj.Ndrive, obj.name)
    end
  else
    % ==== name is not a number or a string...
    error('Invalid argument of type %s', class(name));
  end
