% getFieldMatrix method
%   returns a mOpt, the field transfer matrix for this optic
%
% mOpt = getFieldMatrix(obj, par)

function mOpt = getFieldMatrix(obj, pos, par)
  
  % send inputs to outputs
  mOpt = speye(par.Nrf, par.Nrf);
