% add a position offset via drive index
%   see also addPosOffset
%
% opt = addDriveOffset(opt, nDrv, pos)

function opt = addDriveOffset(opt, nDrv, dx)

  pos = getPosOffset(opt);        % get all pos offsets
  pos(nDrv) = pos(nDrv) + dx;     % change some of them
  opt = setPosOffset(opt, pos);   % set all pos offsets
