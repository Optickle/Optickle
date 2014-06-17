% getReactMatrix method for TEM01 mode (pitch)
%   returns a Ndrive x (Nrf * Nin) x Naf matrix
%
% [mRadAC, mFrc, vRspAF] = getReactMatrix01(obj, pos, vBasis, par)

function [mRadAC, mFrc, vRspAF] = ...
    getReactMatrix01(obj, pos, par, vBin, mOpt, mDirIn, mDirOut, mGen)

  % check for optional arguments
  if nargin < 5
    [mOpt, mDirIn, mDirOut, dldx] = getFieldMatrix(obj, pos, par);
    [~, mGen] = getGenMatrix01(obj, pos, par, vBin, mOpt, dldx);
  end
  
  % constants
  Nrf = par.Nrf;
  vDC = par.vDC;
  Nin = 2;						% obj.Optic.Nin
  Nout = 4;						% obj.Optic.Nout
  LIGHT_SPEED = Optickle.c;
  
  % mechanical response
  vRspAF = getMechResp(obj, par.vFaf, 2);
  
  % output basis, where the basis is undefined, put z = 0, z0 = 1
  vBout = apply(getBasisMatrix(obj), vBin);
  vBout(~isfinite(vBout)) = 1i;

  % input basis, where the basis is undefined, put z = 0, z0 = 1
  vBin(~isfinite(vBin)) = 1i;
  
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
  vWOut = sqrt(z0 .* (1 + (z ./ z0).^2));
  z = real(vBin(:,2));
  z0 = -imag(vBin(:,2));
  vWIn = sqrt(z0 .* (1 + (z ./ z0).^2));
  
  kk=repmat(par.k,1,length(vWOut))';
  vWOut=repmat(vWOut,length(par.k),1);
  mWOut=diag(vWOut.*sqrt(2./kk(:)));
  kk=repmat(par.k,1,length(vWIn))';
  vWIn=repmat(vWIn,length(par.k),1);
  
  mWIn=diag(vWIn.*sqrt(2./kk(:)));
  
  % big mDirIn and mDirOut for all RF components
  mDirInRF = blkdiagN(mDirIn, Nrf);
  mDirOutRF = blkdiagN(mDirOut, Nrf);
  
  % field matrix and derivatives
  mRad = (ctranspose(mOpt) * mDirOutRF * mWOut * mOpt + mDirInRF * mWIn) * vDC / 2;  % CHECK
  mRadAC = 2 / LIGHT_SPEED * ctranspose([mRad; conj(mRad)]);
  
  % radiation reaction force matrix
  mFrc = 4 / LIGHT_SPEED * real(ctranspose(mOpt * vDC) * mDirOutRF * mGen);  % CHECK