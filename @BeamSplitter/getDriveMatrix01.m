% getDriveMatrix method for TEM01 mode
%   returns a matrix, (Nrf * obj.Nout) x (Nrf * obj.Nin) x Ndrive
%   in this case, Nrf * (8 x 4)
%
% mDrv = getDriveMatrix01(obj, pos, vBasis, par)

function mCpl = getDriveMatrix01(obj, pos, par, vBasis, mOpt, dldx)
  
  % check for optional arguments
  if nargin < 6
    [mOpt, ~, ~, dldx] = getFieldMatrix(obj, pos, par);
  end
  
  % constants
  Nrf = par.Nrf;
  Nin = 4;					% obj.Optic.Nin
  Nout = 8;					% obj.Optic.Nout

  % output basis, where the basis is undefined, put z = 0, z0 = 1
  vBout = apply(getBasisMatrix(obj), vBasis);
  vBout(~isfinite(vBout)) = 1i;
  
  % mirror TEM01 mode injection matrix (see @Mirror/getDriveMatrix01)
  z = real(vBout(:,2));
  z0 = -imag(vBout(:,2));
  mInj = diag(sqrt(z0 .* (1 + (z ./ z0).^2)));
  
  % drive matrix
  mCpl = zeros(Nrf * Nout, Nrf * Nin);
  for n = 1:Nrf
    % reflection phase drive coefficient
    drp = 1i * sqrt(par.k(n) / 2) * (mInj * dldx / 2);

    % enter this submatrix into mDrv
    nn = (1:Nout) + Nout * (n - 1);
    mm = (1:Nin) + Nin * (n - 1);
    mCpl(nn, mm) = mOpt(nn, mm) .* drp;
  end
