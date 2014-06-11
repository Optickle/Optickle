% default getReactMatrix method
%   returns a zero matrix, Ndrive x (Nrf * Nin) x Naf
%
% [mRad, mFrc, vRsp] = getReactMatrix(obj, pos, par);

function [mRad, mFrc, vRspAF] = getReactMatrix(obj, pos, par)
  
  mRad = zeros(obj.Ndrive, par.Nrf * obj.Nin);
  mFrc = zeros(obj.Ndrive, obj.Ndrive);
  vRspAF = zeros(par.Naf, obj.Ndrive);

end