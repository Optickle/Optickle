% opt = getDriveOffset(opt, nDrv)
%   get position offset via drive index
%
% The drive index nDrv is in the set of all drives in Optickle
% model (i.e., from 1 to opt.Ndrive).  Typically offsets are more
% naturally specified by optic, as in getPosOffset.
%
% see also setDriveOffset, getPosOffset and setPosOffset

function dx = getDriveOffset(opt, nDrv)
  
  pos = getPosOffset(opt);        % get all pos offsets
  dx = pos(nDrv);                 % select some of them
