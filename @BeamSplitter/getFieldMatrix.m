% getFieldMatrix method
%   returns a mOpt, the field transfer matrix for this optic
%
% [mOpt, mDirIn, mDirOut, dldx] = getFieldMatrix(obj, pos, par)
%
% Example:
% par = opt.getOptParam;
% [mOpt, mOptMir, mDirIn, mDirOut, dldx] = ...
%      opt.optic{nBS}.getFieldMatrix(0, par);

function [mOpt, mOptMir, mDirIn, mDirOut, dldx] = ...
  getFieldMatrix(obj, pos, par, varargin)
  
  % mapping matrices
  [mInArf, mInBrf, mOutArf, mOutBrf] = BeamSplitter.getMirrorIO(par.Nrf);
  
  % get mirror matrix
  [mOptMir, mDirIn, mDirOut, dldx] = ...
    obj.mir.getFieldMatrix(pos, par, varargin{:});
  
  % build coupling matrix
  mOpt = mOutArf * mOptMir * mInArf + mOutBrf * mOptMir * mInBrf;
end
