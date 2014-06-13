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
  Nin = 2;							% obj.Optic.Nin
  Nout = 4;							% obj.Optic.Nout
  Ndrv = 1;
  vDC = par.vDC;
  LIGHT_SPEED = Optickle.c;
  
  % mechanical response
  vRspAF = getMechResp(obj, par.vFaf);
  
  % field matrix and derivatives
  mRad = zeros(Nrf * Nin, Ndrv);
  for n = 1:Nrf
    % enter this submatrix into mRad
    nn = (1:Nout) + Nout * (n - 1);
    mm = (1:Nin) + Nin * (n - 1);
    mRad(mm, 1) = (ctranspose(mOpt(nn, mm)) * ...
      mDirOut * mOpt(nn, mm) + mDirIn) * vDC(mm);
  end
  mRadAC = 2 / LIGHT_SPEED * ctranspose([mRad;conj(mRad)]);
  
  % radiation reaction force matrix
  mFrc = 4 / LIGHT_SPEED * real(ctranspose(mOpt * vDC) * ...
    blkdiagN(mDirOut,Nrf) * mGen);
  
end
