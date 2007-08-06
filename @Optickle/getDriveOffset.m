% get position offset via drive index
%   see also getPosOffset
%
% opt = getDriveOffset(opt, nDrv)

function dx = getDriveOffset(opt, nDrv)
  
  dm = getDriveMap(opt);
  nOpt = dm(nDrv, 1);
  pos = getPosOffset(opt, nOpt);
  dx = pos(dm(nDrv, 2));
