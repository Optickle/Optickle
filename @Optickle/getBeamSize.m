% [w, z0, z, R] = getBeamSize(opt, name, inName)
%
% Determine the beam size on a given optic
% name = name of the optic, or cell array of names
% inName = input name (fr or frA for BS), or cell array of names
%
% w = beam radius on that optic
% z = distance from beam waist to optic (negative means optic is before waist)
% z0 = Rayleigh range of beam incident on optic
% R = radius of curvature of phase front on optic
%
% This function uses getAllFieldBases to compute the relevant basis
% function, and beamRW to compute the beam size and radius of curvature.
%
% Example, beam size on the front of mirror EX:
% wEX = beamSize(optFP, 'EX', 'fr');

%%%%%%%%%%%%%%%%%%%
% contributed by Lisa Barsotti

function [w, z0, z, R] = getBeamSize(opt, name, inName)
  
  % get the basis functions
  vBasis = getAllFieldBases(opt);
  n = getFieldIn(opt, name, inName);
  
  % Distance past the waist and Rayleigh range, Y axis
  z = real(vBasis(n, 2));
  z0 = -imag(vBasis(n, 2));
  
  % compute 
  [R, w] = beamRW(z0, z, opt.lambda);

end
