% getDriveMatrix method for TEM10 mode (yaw)
%   returns the drive coupling matrix, (Nrf * obj.Nout) x (Nrf * obj.Nin) x Ndrive
%   in this case, Nrf * (4 x 2)
%
% arguments not in @Optic/getDriveMatrix01
%   (these are optional and are needed only for optimization)
%   mOpt = optical matrix from getFieldMatrix
%   dldx = (non-zero for reflected fields), from getFieldMatrix
%        = -2 from the front of a mirror at normal incidence (aoi = 0)
%
% mCpl = getDriveMatrix10(obj, pos, vBasis, par, mOpt, dldx)

function mCpl = getDriveMatrix10(obj, pos, vBasis, par, mOpt, dldx)
  
  % check for optional arguments
  if nargin < 6
    [mOpt, ~, ~, dldx] = getFieldMatrix(obj, pos, par);
  end
  
  % constants
  Nrf = par.Nrf;
  Nin = 2;					% obj.Optic.Nin
  Nout = 4;					% obj.Optic.Nout

  % output basis, where the basis is undefined, put z = 0, z0 = 1
  vBout = apply(getBasisMatrix(obj), vBasis);
  vBout(~isfinite(vBout)) = 1i;
  
  % mirror TEM10 mode injections at the waist are
  %   theta / theta0 = theta * sqrt(k * z0 / 2)
  % adding a non-zero distance from the waist, we must scale by
  %   w(z) / w0 = sqrt(1 + (z/z0)^2)
  % The sqrt(k / 2) part is done separately for each RF component
  % the sqrt(z0 * (1 + (z/z0)^2)) is done for each link using the
  % the injection matrix, mInj, computed below.
  %
  %   the x-basis, vBout(:,1), is of interest for the vertical 10 mode
  z = real(vBout(:,1));
  z0 = -imag(vBout(:,1));
  mInj = diag(sqrt(z0 .* (1 + (z ./ z0).^2)));
  
  % drive matrix
  mCpl = zeros(Nrf * Nout, Nrf * Nin);
  for n = 1:Nrf
    % reflection phase drive coefficient
    drp = 1i * sqrt(par.k(n) / 2) * (mInj * sign(-dldx / 2) );

    % enter this submatrix into mCpl
    nn = (1:Nout) + Nout * (n - 1);
    mm = (1:Nin) + Nin * (n - 1);
    mCpl(nn, mm) = mOpt(nn, mm) .* drp;
    
  end
  
end
