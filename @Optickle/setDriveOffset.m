% set position offset via drive index
%   see also setPosOffset
%
% opt = setDriveOffset(opt, nDrv, pos)
% nDrv - drive index
% pos - zero position for this drive (or drives)
%
% How it works:
%  pos = getPosOffset(opt);        % get all pos offsets
%  pos(nDrv) = dx;                 % change some of them
%  opt = setPosOffset(opt, pos);   % set all pos offsets

function opt = setDriveOffset(opt, nDrv, dx)
  
  pos = getPosOffset(opt);        % get all pos offsets
  pos(nDrv) = dx;                 % change some of them
  opt = setPosOffset(opt, pos);   % set all pos offsets
