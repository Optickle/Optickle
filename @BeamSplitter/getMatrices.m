% Get field transfer, reaction and drive matrices for this optic.
%   see also getFieldMatrix, getReactMatrix and getDriveMatrix
%
% This version differs from that of Optic to prevent multiple
% calls to getFieldMatrix by the other get-matrix functions.
%
% [mOptAC, mGenAC, mRadAC, mFrc, vRspAF, mQuant] = getMatrices(obj, pos, par)

function [mOptAC, mGenAC, mRadAC, mFrc, vRspAF, mQuant] = ...
  getMatrices(obj, pos, par)

  % optical field transfer matrix
  [mOpt, mOptMir, mDirIn, mDirOut, dldx] = ...
    obj.getFieldMatrix(pos, par, par.tfType);
  
  % expand to both audio SBs
  mOptAC = Optic.expandFieldMatrixAF(mOpt);

  % reaction, drive and noise matrices (only used in AC computation)
  [mGenAC, mGen] = obj.getGenMatrix(pos, par, mOptMir, dldx);
  [mRadAC, mFrc, vRspAF] = ...
    obj.getReactMatrix(pos, par, mOptMir, mDirIn, mDirOut, mGen);

  mQuant = obj.getNoiseMatrix(pos, par);  
end
