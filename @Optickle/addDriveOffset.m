% add a position offset via drive index
%   see also addPosOffset
%
% opt = addDriveOffset(opt, nDrv, pos)

function opt = addDriveOffset(opt, nDrv, dx)
  
  dm = getDriveMap(opt);
  nOpt = dm(nDrv, 1);
  pos = getPosOffset(opt, nOpt);
  pos(dm(nDrv, 2)) = pos(dm(nDrv, 2)) + dx;
  opt = setPosOffset(opt, nOpt, pos);
  
