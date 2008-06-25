% opt = addDriveOffset(opt, nDrv, pos)
%   add a position offset via drive index
%
% nDrv - drive index
% pos - addition to zero position for this drive
%
% see also addPosOffset
%
% How it works:
%  pos = getPosOffset(opt);        % get all pos offsets
%  pos(nDrv) = pos(nDrv) + dx;     % change some of them
%  opt = setPosOffset(opt, pos);   % set all pos offsets

function opt = addDriveOffset(opt, nDrv, dx)

  pos = getPosOffset(opt);        % get all pos offsets
  pos(nDrv) = pos(nDrv) + dx;     % change some of them
  opt = setPosOffset(opt, pos);   % set all pos offsets
