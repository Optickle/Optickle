% getDriveMatrix method
%   returns a matrix, (Nrf * obj.Nout x (Nrf * obj.Nin) x Ndrive
%
% mDrv = getDriveMatrix(obj, pos, par)

function mDrv = getDriveMatrix(obj, pos, par, mOpt, d)
  
  % check for optional arguments
  if nargin < 5
    [mOpt, d] = getFieldMatrix(obj, pos, par);
  end
  
  % constants
  Nrf = par.Nrf;
  Nin = 2;					% obj.Optic.Nin
  Nout = 4;					% obj.Optic.Nout

  mDrv = zeros(Nrf * Nout, Nrf * Nin);
  for n = 1:Nrf
    % reflection phase drive coefficient
    drp = 1i * par.k(n) * d / 2;

    % enter this submatrix into mDrv
    nn = (1:Nout) + Nout * (n - 1);
    mm = (1:Nin) + Nin * (n - 1);
    mDrv(nn, mm) = mOpt(nn, mm) .* drp;
  end
  
end
