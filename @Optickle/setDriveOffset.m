% set position offset via drive index
%   see also setPosOffset
%
% opt = setDriveOffset(opt, nDrv, pos)

function opt = setDriveOffset(opt, nDrv, dx)
  
  dm = getDriveMap(opt);
  nOpt = dm(nDrv, 1);
  pos = getPosOffset(opt, nOpt);
  pos(dm(nDrv, 2)) = dx;
  opt = setPosOffset(opt, nOpt, pos);
  
