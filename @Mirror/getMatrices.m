% Get field transfer, reaction and drive matrices for this optic.
%   see also getFieldMatrix, getReactMatrix and getDriveMatrix
%
% This version differs from that of Optic to prevent multiple
% calls to getFieldMatrix by the other get-matrix functions.
%
% [mOptAC, mGenAC, mRad, mFrc, mRsp, mQuant] = getMatrices(obj, pos, par)

function [mOptAC, mGenAC, mRad, mFrc, mRsp, mQuant] = getMatrices(obj, pos, par)

  % optical field transfer matrix
  [mOpt, mDirIn, mDirOut, dldx] = getFieldMatrix(obj, pos, par);
  
  % expand to both audio SBs
  mOptAC = Optic.expandFieldMatrixAF(mOpt);

  % reaction, drive and noise matrices (only used in AC computation)
  [mGenAC, mGen] = getGenMatrix(obj, pos, par, mOpt, dldx);
  [mRad, mFrc, mRsp] = ...
    getReactMatrix(obj, pos, par, mOpt, mDirIn, mDirOut, mGen);

  mQuant = getNoiseMatrix(obj, pos, par);  
end
