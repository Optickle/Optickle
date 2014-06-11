% getFieldMatrixAC method
%   returns a mOptAC, the field transfer matrix for this optic
%
% mOptAC = getFieldMatrixAC(obj, par)

function [mOptAC, mDirin, mDirout, dldx] = getFieldMatrixAC(obj, pos, par)

  [mOpt, mDirin, mDirout, dldx] = getFieldMatrix(obj, pos, par);
  mOptAC = [mOpt,mOpt*0;mOpt*0,conj(mOpt)];

end
