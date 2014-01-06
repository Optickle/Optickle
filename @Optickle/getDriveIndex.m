% n = getDriveIndex(opt, name, driveType)
%   deprecated, use getDriveNum instead

function nOut = getDriveIndex(opt, name, varargin)

  nOut = getDriveNum(opt, name, varargin{:});
  
end
