% getGenMatrix method
%   returns a matrix, (2 * Nfld) x Ndrive
%
% mGen = getGenMatrix(obj, pos, par)

function mGen = getGenMatrix(obj, pos, par)
   
  % constants
  vDCin = par.vDCin;                % is it named like this??????????

  mCpl = getDriveMatrix(obj, pos, par, mOptAC, dldx);
  mGen1 = mCpl * vDCin;
  mGen = [mGen1;conj(mGen1)];
  
end
