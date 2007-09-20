% Get field transfer, reaction and drive matrices for this optic.
%   see also getFieldMatrix, getReactMatrix and getDriveMatrix
%
% This version differs from that of Optic to prevent multiple
% calls to getFieldMatrix by the other get-matrix functions.
%
% [mOpt, mRct, mDrv] = getMatrices01(obj, pos, vBasis, par);

function [mOpt, mRct, mDrv] = getMatrices01(obj, pos, vBasis, par)

  % optical field transfer matrix
  [mOpt, d] = getFieldMatrix(obj, pos, par);

  % reaction, drive and noise matrices (only used in AC computation)
  mRct = getReactMatrix01(obj, pos, vBasis, par, mOpt, d);
  mDrv = getDriveMatrix01(obj, pos, vBasis, par, mOpt, d);
