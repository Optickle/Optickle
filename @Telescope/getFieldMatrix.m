% getFieldMatrix method
%   returns a mOpt, the field transfer matrix for this optic
%
% mOpt = getFieldMatrix(obj, pos, par)

function mOpt = getFieldMatrix(obj, pos, par)
  
  if isempty(obj.df)
    % send inputs to outputs
    mOpt = speye(par.Nrf, par.Nrf);
  else
    % account for RF propagation phase
    d = sum(obj.df(:, 1));
    v = exp(1i * d * par.k);
    
    % send inputs to outputs
    mOpt = sparse(diag(v));
  end
