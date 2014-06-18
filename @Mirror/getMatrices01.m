% Get field transfer, reaction and drive matrices for this optic.
%   see also getFieldMatrix, getReactMatrix and getDriveMatrix
%
% This version differs from that of Optic to prevent multiple
% calls to getFieldMatrix by the other get-matrix functions.
%
% [mOptAC, mGenAC, mRadAC, mFrc, vRspAF, mQuant] =
% getMatrices01(obj, pos, par, vBasis)

function [mOptAC, mGenAC, mRadAC, mFrc, vRspAF, mQuant] = ...
  getMatrices01(obj, pos, par, vBin)

  % optical field transfer matrix
  [mOpt, mDirIn, mDirOut, dldx] = getFieldMatrix(obj, pos, par);

  % expand to both audio SBs
  mOptAC = Optic.expandFieldMatrixAF(mOpt);

  % reaction, drive and noise matrices (only used in AC computation)
  %  [mGenAC, mGen] = getGenMatrix01(obj, pos, par, mOpt, dldx);
    [mGenAC, mGen] = getGenMatrix01(obj, pos, par, vBin, mOpt, dldx);
  [mRadAC, mFrc, vRspAF] = ...
    getReactMatrix01(obj, pos, par, vBin, mOpt, mDirIn, mDirOut, mGen);

  mQuant = getNoiseMatrix01(obj, pos, par);

end
