% getDriveMatrix method
%   returns the drive coupling matrix, Nrf * (obj.Nout x obj.Nin)
%
% mCpl = getDriveMatrix(obj, pos, par)

function mCpl = getDriveMatrix(obj, pos, par, mOpt, dldx)
  
  % check for optional arguments
  if nargin < 4
    [mOpt, ~, ~, dldx] = getFieldMatrix(obj, pos, par);
  end
  
  % constants
  Nrf = par.Nrf;
  Nin = 4;					% obj.Optic.Nin
  Nout = 8;					% obj.Optic.Nout

  mCpl = zeros(Nrf * Nout, Nrf * Nin);
  for n = 1:Nrf
    % reflection phase drive coefficient
    drp = 1i * par.k(n) * dldx / 2;

    % enter this submatrix into mDrv
    nn = (1:Nout) + Nout * (n - 1);
    mm = (1:Nin) + Nin * (n - 1);
    mCpl(nn, mm) = mOpt(nn, mm) .* drp;
  end
end