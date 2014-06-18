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
  
  % make A-side and B-side parameter structs
  parA = par;
  parA.vDC = mInArf * par.vDC;
  parA.vBin = par.vBin(1:2, :);

  parB = par;
  parB.vDC = mInBrf * par.vDC;
  parB.vBin = par.vBin(3:4, :);
  
  % get mirror matrix
  mCplA = obj.mir.getDriveMatrix(pos, parA, mOpt, dldx);
  mCplB = obj.mir.getDriveMatrix(pos, parB, mOpt, dldx);
  
  % build coupling matrix
  mCpl = mOutArf * mCplA * mInArf + mOutBrf * mCplB * mInBrf;
end
