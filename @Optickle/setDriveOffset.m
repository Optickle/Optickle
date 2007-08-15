% set position offset via drive index
%   see also setPosOffset
%
% opt = setDriveOffset(opt, nDrv, pos)

function opt = setDriveOffset(opt, nDrv, dx)
  
  pos = getPosOffset(opt);        % get all pos offsets
  pos(nDrv) = dx;                 % change some of them
  opt = setPosOffset(opt, pos);   % set all pos offsets
