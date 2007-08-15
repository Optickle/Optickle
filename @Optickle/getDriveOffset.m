% get position offset via drive index
%   see also getPosOffset
%
% opt = getDriveOffset(opt, nDrv)

function dx = getDriveOffset(opt, nDrv)
  
  pos = getPosOffset(opt);        % get all pos offsets
  dx = pos(nDrv);                 % select some of them
