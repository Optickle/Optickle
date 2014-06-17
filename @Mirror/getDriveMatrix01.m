% getDriveMatrix method for TEM01 mode (pitch) or TEM10 mode(yaw)
%   returns the drive coupling matrix, (Nrf * obj.Nout) x (Nrf * obj.Nin) x Ndrive
%   in this case, Nrf * (4 x 2)
%
% arguments not in @Optic/getDriveMatrix01
%   (these are optional and are needed only for optimization)
%   mOpt = optical matrix from getFieldMatrix
%   dldx = (non-zero for reflected fields), from getFieldMatrix
%        = -2 from the front of a mirror at normal incidence (aoi = 0)
%
% mCpl = getDriveMatrix01(obj, pos, vBasis, par, mOpt, dldx)

function mCpl = getDriveMatrix01(obj, pos, par, vBasis, mOpt, dldx)
  
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
  
  % select 01 (pitch) or 10 (yaw)
  if par.is10
      %10 (yaw) case
      nBasis = 1;
      dPhidTheta = sign(dldx / 2); %%%% CHECK SIGN%%%%%%%%
                                   % Yaw of output beam for yaw of mirror.
                                   % To understand where the factor of
                                   % 1/2 comes from consider the
                                   % longitudinal case - phase change
                                   % on reflection is i k 2x but
                                   % sideband amplitudes are i k
                                   % x. Due to the sign the
                                   % division doesn't actually do
                                   % anything here. It is just
                                   % included for consistency
  else
      %01 (pitch) case - default
      nBasis = 2;
      dPhidTheta = dldx / 2; %Pitch of output beam for pitch of
                             %mirror. Includes cos(angle of incidence)
                             %in pitch case. The `sign' removes this
                             %in the yaw case.
  end
  
      
  
  % mirror TEM01/10 mode injections at the waist are
  %   theta / theta0 = theta * sqrt(k * z0 / 2)
  % adding a non-zero distance from the waist, we must scale by
  %   w(z) / w0 = sqrt(1 + (z/z0)^2)
  % The sqrt(k / 2) part is done separately for each RF component
  % the sqrt(z0 * (1 + (z/z0)^2)) is done for each link using the
  % the injection matrix, mInj, computed below.
  %
 
  %   the y-basis, vBout(:,2), is of interest for the vertical 01
  %   mode
  %   the x-basis, vBout(:,1), is of interest for the horizontal 10 mode
  z    =  real(vBout(:,nBasis));
  z0   = -imag(vBout(:,nBasis));
  mInj = diag(sqrt(z0 .* (1 + (z ./ z0).^2))); %sqrt(z0*w(z)/w0)
  
  % drive matrix
  mCpl = zeros(Nrf * Nout, Nrf * Nin);
  for n = 1:Nrf
    % reflection phase drive coefficient
    drp = 1i * sqrt(par.k(n) / 2) * (mInj * dPhidTheta);

    % enter this submatrix into mCpl
    nn = (1:Nout) + Nout * (n - 1);
    mm = (1:Nin) + Nin * (n - 1);
    mCpl(nn, mm) = mOpt(nn, mm) .* drp;
    
  end
  
end
