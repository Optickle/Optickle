% default getReactMatrix01 method
%   returns a zero matrix, Ndrive x (Nrf * Nin) x Naf
%
% mRct = getReactMatrix01(obj, par)

function mRct = getReactMatrix01(obj, pos, vBasis, par)
  
  mRct = zeros(obj.Ndrive, par.Nrf * obj.Nin, par.Naf);

end
