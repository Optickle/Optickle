% getFieldMatrix method
%   returns a mOpt, the field transfer matrix for this optic
%
% mOpt = getFieldMatrix(obj, par)

function mOpt = getFieldMatrix(obj, pos, par)

  % constants
  Nin = obj.Nin;		% always 0
  Nout = obj.Nout;	% always 1

  % make empty sparse matrix with correct dimentions (Nrf x 0)
  mOpt = sparse(par.Nrf * Nout, par.Nrf * Nin);
end
