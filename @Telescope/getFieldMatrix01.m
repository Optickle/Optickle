% getFieldMatrix01 method
%   returns a mOpt, the field transfer matrix for this optic
%   a telescope adds Gouy phase for the TEM01 mode
%
% mOptAC = getFieldMatrix01(obj, par)

function mOptAC = getFieldMatrix01(obj, pos, par, vBin)
  
  % compute Gouy phase
  phi = getTelescopePhase(obj, vBin);
  
  % send inputs to outputs with Gouy phase (y-basis... TEM01 mode)
  mOpt = getFieldMatrix(obj, pos, par) * exp(1i * phi(2));
  
  mOptAC = Optic.expandFieldMatrixAF(mOpt);
