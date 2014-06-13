% getFieldMatrix method
%   returns a mOpt, the field transfer matrix for this optic
%
% mOpt = getFieldMatrix(obj, par)

function mOpt = getFieldMatrix(obj, pos, par)
  
  % send inputs to outputs, will some loss
  mOpt = speye(par.Nrf, par.Nrf) * sqrt(1 - obj.loss);
