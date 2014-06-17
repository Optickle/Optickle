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
    [mOpt, mDirIn, mDirOut, dldx] = getFieldMatrix(obj, pos, par);
    [~, mGen] = getGenMatrix(obj, pos, par, mOpt, dldx);
  end
  
  % constants
  Nrf = par.Nrf;
  vDC = par.vDC;
  LIGHT_SPEED = Optickle.c;
  
  % mechanical response
  vRspAF = getMechResp(obj, par.vFaf);
  
  % big mDirIn and mDirOut for all RF components
  mDirInRF = blkdiagN(mDirIn, Nrf);
  mDirOutRF = blkdiagN(mDirOut, Nrf);
  
  % field matrix and derivatives
  mRad = (ctranspose(mOpt) * mDirOutRF * mOpt + mDirInRF) * vDC;
  mRadAC = 2 / LIGHT_SPEED * ctranspose([mRad; conj(mRad)]);
  
  % radiation reaction force matrix
  mFrc = 4 / LIGHT_SPEED * real(ctranspose(mOpt * vDC) * mDirOutRF * mGen);
  
end