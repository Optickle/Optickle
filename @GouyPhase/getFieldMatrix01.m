% getFieldMatrix01 method
%   returns a mOpt, the field transfer matrix for this optic
%   a telescope adds Gouy phase for the TEM01 mode
%
% mOptAC = getFieldMatrix01(obj, pos, par)

function mOptAC = getFieldMatrix01(obj, pos, par, vBin)
  
  % send inputs to outputs with Gouy phase
  mOpt = getFieldMatrix(obj, pos, par) * exp(1i * obj.phi);
  mOptAC = Optic.expandFieldMatrixAF(mOpt);
  
