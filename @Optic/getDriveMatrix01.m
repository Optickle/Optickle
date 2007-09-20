% getDriveMatrix01 method
%   returns an empty matrix
%
% mDrv = getDriveMatrix01(obj, pos, vBasis, par)

function mDrv = getDriveMatrix01(obj, pos, vBasis, par)

  mDrv = zeros(obj.Nout * par.Nrf, obj.Nin * par.Nrf, obj.Ndrive);
