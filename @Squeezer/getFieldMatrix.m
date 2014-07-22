% getFieldMatrix method
%   returns a mOpt, the field transfer matrix for this optic
%
% mOpt = getFieldMatrix(obj, par)

function mOpt = getFieldMatrix(obj, pos, par)
  % As of now, The squeezer does not modify the DC fields in Optickle
  mOpt = speye(par.Nrf, par.Nrf);

end
