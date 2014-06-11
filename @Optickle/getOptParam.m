% par = getOptParam(opt)
%
% extract some basic parameters from an Optickle model
%   used by getFieldMatrix, getDriveMatrix, etc.
%
% parameters are: h, c, minQuant, lambda, k, Nrf, vFrf

function par = getOptParam(opt)
  
  par.h = opt.h;
  par.c = opt.c;
  par.minQuant = opt.minQuant;
  par.lambda = opt.lambda;
  par.k = opt.k;
  par.Nrf = length(opt.vFrf);
  par.vFrf = opt.vFrf;
  par.lambda = opt.lambda;
  par.pol = opt.pol;
