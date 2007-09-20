% getFieldMatrix01 method
%   returns a mOpt, the field transfer matrix for this optic
%   a telescope adds Gouy phase for the TEM01 mode
%
% mOpt = getFieldMatrix01(obj, par)

function mOpt = getFieldMatrix01(obj, pos, vBasis, par)
  
  % compute Gouy phase
  phi = getTelescopePhase(obj, vBasis);
  
  % send inputs to outputs with Gouy phase (y-basis... TEM01 mode)
  mOpt = getFieldMatrix(obj, pos, par) * exp(i * phi(2));
