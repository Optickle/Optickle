% getDriveMatrix method
%   returns the drive coupling matrix, Nrf * (obj.Nout x obj.Nin)
%
% mCpl = getDriveMatrix(obj, pos, par)

function mCpl = getDriveMatrix(obj, pos, par, mOpt, dldx)
  
  % check for optional arguments
  if nargin < 4
    [mOpt, ~, ~, dldx] = obj.mir.getFieldMatrix(pos, par, par.tfType);
  end
  
  % mapping matrices
  [mInArf, mInBrf, mOutArf, mOutBrf] = BeamSplitter.getMirrorIO(par.Nrf);
  
  % get mirror matrix
  mCplMir = obj.mir.getDriveMatrix(pos, par, mOpt, dldx);
  
  % build coupling matrix
  mCpl = mOutArf * mCplMir * mInArf + mOutBrf * mCplMir * mInBrf;
end
