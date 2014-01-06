% default getReactMatrix method
%   returns a zero matrix, Ndrive x (Nrf * Nin) x Naf
%
% mRct = getReactMatrix(obj, par)

function mRct = getReactMatrix(obj, pos, par)
  
  mRct = zeros(obj.Ndrive, par.Nrf * obj.Nin, par.Naf);
