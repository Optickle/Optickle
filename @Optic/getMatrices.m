% Get field transfer, reaction, drive and quantum matrices for this optic.
%   see also getFieldMatrix, getReactMatrix, getDriveMatrix and getNoiseMatrix
%
% The parameter struct is
%  par.c = opt.c;
%  par.lambda = opt.lambda;
%  par.k = opt.k + 2 * pi * vFrf / opt.c;
%  par.Nrf = Nrf;
%  par.vFrf = vFrf;
%  par.Naf = Naf;
%  par.vFaf = f;
%
% [mOpt, mRct, mDrv, mQuant] = getMatrices(obj, pos, par);

function [mOptAC, mGen, mRad, mFrc, mRsp, mQuant] = getMatrices(obj, pos, par)

  % optical field transfer matrix
  mOptAC = getFieldMatrixAC(obj, pos, par);

  % reaction, drive and noise matrices (only used in AC computation)
  if par.Naf > 0
    [mRad, mFrc, mRsp] = getReactMatrix(obj, pos, par);
    mGen = getGenMatrix(obj, pos, par);
    mQuant = getNoiseMatrix(obj, pos, par);
  else
    mRad = [];
    mFrc = [];
    mRsp = [];
    mGen = [];
    mQuant = [];
  end
end
