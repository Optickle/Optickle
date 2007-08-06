% par = getOptParam(opt)
%
% extract some basic parameters from an Optickle model
%   used by getFieldMatrix, getDriveMatrix, etc.

function par = getOptParam(opt)
  
  par.h = opt.h;
  par.c = opt.c;
  par.minQuant = opt.minQuant;
  par.lambda = opt.lambda;
  par.k = opt.k + 2 * pi * opt.vFrf / opt.c;
  par.Nrf = length(opt.vFrf);
  par.vFrf = opt.vFrf;
