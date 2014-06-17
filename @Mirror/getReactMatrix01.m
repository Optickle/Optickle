% getReactMatrix method for TEM01 mode (pitch)
%   returns a Ndrive x (Nrf * Nin) x Naf matrix
%
% mDrv = getReactMatrix01(obj, pos, vBasis, par)

function [mRadAC, mFrc, vRspAF] = ...
    getReactMatrix01(obj, pos, par, mOpt, mDirIn, mDirOut, mGen)

  % mRct = getReactMatrix01(obj, pos, vBasis, par, mOpt, d)

  % check for optional arguments
  if nargin < 4
    [mOpt, mDirIn, mDirOut, dldx] = getFieldMatrix(obj, pos, par);
    [~, mGen] = getGenMatrix(obj, pos, par, mOpt, dldx);
  end
  
  % constants
  Nrf = par.Nrf;
  vDC = par.vDC;
  Nin = 2;						% obj.Optic.Nin
  Nout = 4;						% obj.Optic.Nout

  % mechanical response
  vRspAF = getMechResp(obj, par.vFaf, 2);
  
  % output basis, where the basis is undefined, put z = 0, z0 = 1
  vBout = apply(getBasisMatrix(obj), vBasis);
  vBout(~isfinite(vBout)) = 1i;
  
  % mirror TEM01 mode reaction torque scales with beam size
  %   torque = R * w * (A01 * A00)
  % so here the reaction is proportional to waist size
  %   w = sqrt(z0 * (1 + (z/z0)^2)) * sqrt(2 / k)
  % The sqrt(2 / k) part is done separately for each RF component
  % the sqrt(z0 * (1 + (z/z0)^2)) is done for each link using the
  % the waist size matrix, mW, computed below.
  %
  %   the y-basis, vBout(:,2), is of interest for the vertical 01 mode
  z = real(vBout(:,2));
  z0 = -imag(vBout(:,2));
  mW = diag(sqrt(z0 .* (1 + (z ./ z0).^2)));
  
  % reflection reaction coefficient
  reac = repmat(mW*sqrt(2./par.k).',Nin,1);
  reac = diag(reac(:));
  
  % big mDirIn and mDirOut for all RF components
  mDirInRF = blkdiagN(mDirIn, Nrf);
  mDirOutRF = blkdiagN(mDirOut, Nrf);
  
  % field matrix and derivatives
  mRad = (ctranspose(mOpt) * mDirOutRF * mOpt + mDirInRF) * reac/2 * vDC;  % CHECK
  mRadAC = 2 / LIGHT_SPEED * ctranspose([mRad; conj(mRad)]);
  
  % radiation reaction force matrix
  mFrc = 4 / LIGHT_SPEED * real(ctranspose(mOpt * vDC) * mDirOutRF * mGen);  % CHECK