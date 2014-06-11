% getDriveMatrix method
%   returns a matrix, (Nrf * obj.Nout) x (Nrf * obj.Nin) x Ndrive
%
% mCpl = getDriveMatrix(obj, pos, par)

function mCpl = getDriveMatrix(obj, pos, par, mOptAC, dldx)
  
  % check for optional arguments
  if nargin < 5
    [mOptAC, ~, ~, dldx] = getFieldMatrixAC(obj, pos, par);
  end
  
  % constants
  Nrf = par.Nrf;
  Nin = 2;					% obj.Optic.Nin
  Nout = 4;					% obj.Optic.Nout

  mCpl = zeros(Nrf * Nout, Nrf * Nin);
  for n = 1:Nrf
    % reflection phase drive coefficient
    drp = 1i * par.k(n) * dldx / 2;

    % enter this submatrix into mDrv
    nn = (1:Nout) + Nout * (n - 1);
    mm = (1:Nin) + Nin * (n - 1);
    mCpl(nn, mm) = mOptAC(nn, mm) .* drp;
  end
  
end
