% getReactMatrix method
%   returns  mRadAC: Ndrive x (2 * Nrf * Nin) matrix (for mFieldOptic)
%            mFrc: Ndrive x Ndrive matrix  (for mOpticOptic)
%            vRspAF: Naf vector    (mechanical response vector)
%
% [mRadAC,mFrc,vRspAF] = getReactMatrix(obj, pos, par)
% or [ ... ] = getReactMatrix(obj, pos, par, mOpt, mDirIn, mDirOut, mGen)
%  where all of the extra arguments are from the internal mirror object
%  and are there only for optimization!

function [mRadAC, mFrc, vRspAF] = ...
  getReactMatrix(obj, pos, par, mOpt, mDirIn, mDirOut, mGen)
  
  % mapping matrices
  [mInArf, mInBrf, mOutArf, mOutBrf] = BeamSplitter.getMirrorIO(par.Nrf);
  
  % make A-side and B-side parameter structs
  parA = par;
  parA.vDC = mInArf * par.vDC;

  parB = par;
  parB.vDC = mInBrf * par.vDC;
  
  if par.tfType ~= Optickle.tfPos
    parA.vBin = par.vBin(1:2, :);
    parB.vBin = par.vBin(3:4, :);
  end
  
  % check for optional arguments
  if nargin < 4
    [mOpt, mDirIn, mDirOut, dldx] = ...
      obj.mir.getFieldMatrix(pos, par, par.tfType);
    
    % get mGen for A-side and B-side
    [~, mGenA] = obj.mir.getGenMatrix(pos, parA, mOpt, dldx);
    [~, mGenB] = obj.mir.getGenMatrix(pos, parB, mOpt, dldx);
  else
    % split mGen into A-side and B-side
    mGenA = mOutArf.' * mGen;
    mGenB = mOutBrf.' * mGen;
  end
  
  % mapping matrices, for upper and lower ASBs
  [mInArf, mInBrf] = BeamSplitter.getMirrorIO(2 * par.Nrf);
  
  % get radiation and force matrices for both sides
  [mRadA, mFrcA, vRspAF] = ...
    obj.mir.getReactMatrix(pos, parA, mOpt, mDirIn, mDirOut, mGenA);
  [mRadB, mFrcB] = ...
    obj.mir.getReactMatrix(pos, parB, mOpt, mDirIn, mDirOut, mGenB);
  
  % build total radiation and force matrices
  mRadAC = mRadA * mInArf + mRadB * mInBrf;
  mFrc = mFrcA + mFrcB;
end