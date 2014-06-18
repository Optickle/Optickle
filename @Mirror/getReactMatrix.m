% getReactMatrix method
%   returns  mRadAC: Ndrive x (2 * Nrf * Nin) matrix (for mFieldOptic)
%            mFrc: Ndrive x Ndrive matrix  (for mOpticOptic)
%            vRspAF: Naf vector    (mechanical response vector)
%
% [mRadAC,mFrc,vRspAF] = getReactMatrix(obj, pos, par)
% or [ ... ] = getReactMatrix(obj, pos, par, mOpt, mDirIn, mDirOut, mGen)

function [mRadAC,mFrc,vRspAF] = ...
  getReactMatrix(obj, pos, par, mOpt, mDirIn, mDirOut, mGen)
  
  % check for optional arguments
  if nargin < 4
    [mOpt, mDirIn, mDirOut, dldx] = getFieldMatrix(obj, pos, par, par.tfType);
    [~, mGen] = getGenMatrix(obj, pos, par, mOpt, dldx);
  end
  
  % constants
  Nrf = par.Nrf;
  vDC = par.vDC;
  LIGHT_SPEED = Optickle.c;
  
  % mechanical response
  if par.tfType == Optickle.tfPos
      nDOF = 1;
  elseif par.tfType == Optickle.tfPit
      nDOF = 2;
  elseif par.tfType == Optickle.tfYaw
      nDOF = 3;
  end
  
  vRspAF = getMechResp(obj, par.vFaf, nDOF);
  
  % big mDirIn and mDirOut for all RF components
  mDirInRF  = blkdiagN(mDirIn, Nrf);
  mDirOutRF = blkdiagN(mDirOut, Nrf);
  
  
  if par.tfType ~= Optickle.tfPos %pit or yaw case
      
      % output basis, where the basis is undefined, put z = 0, z0 = 1
      vBout = apply(getBasisMatrix(obj), par.vBin);
      vBout(~isfinite(vBout)) = 1i;

      % input basis, where the basis is undefined, put z = 0, z0 = 1
      vBin(~isfinite(par.vBin)) = 1i;
  
      % mirror TEM01/10 mode reaction torque scales with beam size
      %   torque = R * w * (A01/10 * A00)
      % so here the reaction is proportional to waist size
      %   w = sqrt(z0 * (1 + (z/z0)^2)) * sqrt(2 / k)
      % The sqrt(2 / k) part is done separately for each RF component
      % the sqrt(z0 * (1 + (z/z0)^2)) is done for each link using the
      % the waist size matrix, mW, computed below.
      %
      %   the y-basis, vBout(:,2), is of interest for the vertical 01
      %   mode
      %   the x-basis, vBout(:,1), is of interest for the horizontal 10 mode
      z     =  real(vBout(:, par.nBasis));
      z0    = -imag(vBout(:, par.nBasis));
      vWOut = sqrt(z0 .* (1 + (z ./ z0).^2));
      z     =  real(par.vBin(:, par.nBasis));
      z0    = -imag(par.vBin(:, par.nBasis));
      vWIn  = sqrt(z0 .* (1 + (z ./ z0).^2));
      
      kk    = repmat(par.k, 1, length(vWOut))';
      vWOut = repmat(vWOut, length(par.k), 1);
      mWOut = diag(vWOut .* sqrt(2 ./ kk(:)));
      kk    = repmat(par.k, 1, length(vWIn))';
      vWIn  = repmat(vWIn, length(par.k), 1);
  
      mWIn  = diag(vWIn .* sqrt(2 ./ kk(:)));
  
  
      % field matrix
      mRad = (ctranspose(mOpt) * mDirOutRF * mWOut * mOpt + mDirInRF * mWIn) * vDC / 2;  % CHECK

  else % pos case
  
      % field matrix
      mRad = (ctranspose(mOpt) * mDirOutRF * mOpt + mDirInRF) * vDC;
  
  end
  
  % derivatives
  mRadAC = 2 / LIGHT_SPEED * ctranspose([mRad; conj(mRad)]);
  % radiation reaction force matrix
  mFrc = 4 / LIGHT_SPEED * real(ctranspose(mOpt * vDC) * mDirOutRF * mGen);
  
end
