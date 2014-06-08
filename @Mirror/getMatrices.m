% Get field transfer, reaction and drive matrices for this optic.
%   see also getFieldMatrix, getReactMatrix and getDriveMatrix
%
% This version differs from that of Optic to prevent multiple
% calls to getFieldMatrix by the other get-matrix functions.
%
% [mOpt, mRct, mDrv, mQuant] = getMatrices(obj, pos, par);

function [mOpt, mRct, mDrv, mQuant] = getMatrices(obj, pos, par)

  % optical field transfer matrix
  [mOpt, d] = getFieldMatrix(obj, pos, par);

  % reaction, drive and noise matrices (only used in AC computation)
  if par.Naf > 0
    mRct = getReactMatrix(obj, pos, par, mOpt, d);
    mDrv = getDriveMatrix(obj, pos, par, mOpt, d);
    mQuant = getNoiseMatrix(obj, pos, par);
  else
    mRct = [];
    mDrv = [];
    mQuant = [];
  end

end
