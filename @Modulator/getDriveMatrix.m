% getDriveMatrix method
%   returns a sparse matrix, Nrf * (obj.Nout x obj.Nin)
%
% mDrv = getDriveMatrix(obj, pos, par)

function mDrv = getDriveMatrix(obj, pos, par)
  
  % constants
  Nrf = par.Nrf;

  if obj.Nmod == 1
    mDrv = eye(Nrf, Nrf) * obj.cMod / 2;
  elseif obj.Nmod == Nrf
    mDrv = diag(cMod / 2);
  else
    error('Modulator %d has invalid modulation vector.', obj.sn);
  end
end
