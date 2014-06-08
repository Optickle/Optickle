% getFieldMatrix01 method for TEM01 mode
%   returns a mOpt, the field transfer matrix for this optic
%   this is the default... just use getFieldMatrix as for TEM00 mode
%
% mOpt = getFieldMatrix01(obj, pos, vBasis, par)

function mOpt = getFieldMatrix01(obj, pos, vBasis, par)

  % same for TEM00 and TEM01
  mOpt = getFieldMatrix(obj, pos, par);
