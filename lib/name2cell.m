% nameList = name2cell(name)
%   input name may be any of:
%     a name string
%     a serial number (port, optic, drive, etc.)
%     a vector of serial numbers
%     a cell array of names and/or serial numbers
%
%   output nameList is a cell array of names and/or serial numbers

function name = name2cell(name)
  
  if ~iscell(name)
    % non-cell input, check and wrap it
    if ischar(name)
      name = {name};
    elseif isnumeric(name)
      name = num2cell(name);
    else
      error('Invalid argument of type %s', class(name));
    end
  else
    % check types
    for n = 1:numel(name)
      if ~ischar(name{n}) && ~isnumeric(name{n})
        error('Invalid name argument of type %s', class(name{n}));
      end
    end
  end
  
end
  
