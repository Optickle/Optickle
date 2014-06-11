% getReactMatrix method
%   returns  mRad: Ndrive x (2 * Nrf * Nin) matrix
%            mResp: Naf vector
%            mFrc: Ndrive x Ndrive matrix
%
% [mRad,mResp,mFrc] = getReactMatrix(obj, pos, par)

function [mRadAC,mFrc,mRsp] = getReactMatrix(obj, pos, par, mOptAC, mDirIn, mDirOut)
  
  % check for optional arguments
  if nargin < 5
    [mOpt, mDirIn, mDirOut, dldx] = getFieldMatrix(obj, pos, par);
  end
  
  % constants
  Nrf = par.Nrf;
  Nin = 2;							% obj.Optic.Nin
  Nout = 4;							% obj.Optic.Nout
  vDC = par.vDC;
  LIGHT_SPEED = Optickle.c;
  
  % mechanical response
  mRsp = getMechResp(obj, par.vFaf);
  
  % field matrix and derivatives
  mRad = zeros(1, Nrf * Nin);
  for n = 1:Nrf
    % enter this submatrix into mRad1
    nn = (1:Nout) + Nout * (n - 1);
    mm = (1:Nin) + Nin * (n - 1);
    mRad(1, mm) = (ctranspose(mOpt(nn, mm)) * mDirOut * mOpt(nn, mm) + mDirIn) * vDC;
  end
  mRadAC = 2 / LIGHT_SPEED * ctranspose([mRad;conj(mRad)]);
  
  % radiation reaction force matrix
  [~,mGen] = getGenMatrix(obj, pos, par, mOpt, dldx);
  mFrc = 4 / LIGHT_SPEED * real(ctranspose(vDCin) * ctranspose(mOptAC(1:Nout, 1:Nin)) * mDirOut * mGen);
  
end
