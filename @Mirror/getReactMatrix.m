% getReactMatrix method
%   returns  mRad: Ndrive x (2 * Nrf * Nin) matrix
%            mResp: Naf vector
%            mFrc: Ndrive x Ndrive matrix
%
% [mRad,mResp,mFrc] = getReactMatrix(obj, pos, par)

function [mRad,mFrc,mResp] = getReactMatrix(obj, pos, par, mOptAC, mDirin, mDirout)
  
  % check for optional arguments
  if nargin < 5
    [mOptAC, mDirin, mDirout, ~] = getFieldMatrixAC(obj, pos, par);
  end
  
  % constants
  Nrf = par.Nrf;
  Nin = 2;							% obj.Optic.Nin
  Nout = 4;							% obj.Optic.Nout
  vDCin = par.vDCin;                % is it named like this??????????
  LIGHT_SPEED = Optickle.c;
  
  % mechanical response
  mResp = getMechResp(obj, par.vFaf);
  
  % field matrix and derivatives
  mRad1 = zeros(1, Nrf * Nin);
  for n = 1:Nrf
    % enter this submatrix into mRad1
    nn = (1:Nout) + Nout * (n - 1);
    mm = (1:Nin) + Nin * (n - 1);
    mRad1(1, mm) = (ctranspose(mOptAC(nn, mm)) * mDirout * mOptAC(nn, mm) + mDirin) * vDCin;
  end
  mRad = 2 / LIGHT_SPEED * ctranspose([mRad1;conj(mRad1)]);
  
  % radiation reaction force matrix
  mGen = getGenMatrix(obj, pos, par);
  mGen1 = mGen(1:size(mGen,1)/2,:);
  mFrc = 4 / LIGHT_SPEED * real(ctranspose(vDCin) * ctranspose(mOptAC(1:Nout, 1:Nin)) * mDirout * mGen1);
  
end
