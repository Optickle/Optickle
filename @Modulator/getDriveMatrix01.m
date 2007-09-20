% getDriveMatrix method for TEM01 mode
%   returns a sparse matrix, Nrf * (obj.Nout x obj.Nin)
%
% HACK - for now this is just the same as for TEM00
%   so an AM modulator generates beam shift, PM generates beam angle
%
% mDrv = getDriveMatrix(obj, pos, par)

function mDrv = getDriveMatrix01(obj, pos, vBasis, par)
  
  % constants
  Nrf = par.Nrf;

  if obj.Nmod == 1
    mDrv = eye(Nrf, Nrf) * obj.cMod / 2;
  elseif obj.Nmod == Nrf
    mDrv = diag(cMod / 2);
  else
    error('Modulator %d has invalid modulation vector.', obj.sn);
  end
