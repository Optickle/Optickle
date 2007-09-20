% [R, w] = beamRW(z0, z, lambda)
%
% lambda - laser wavelength
% z0 - Rayleigh Range of the beam
% z - distance past the waist of this beam cross-section
% R - wave front radius of curvature
% w - beam radius at a beam cross-section (1/e^2 in power)
%
% Some trivia... Given the following:
%   [R0, w0] = beamRW(z0, 0, lambda);
%   [R1, w1] = beamRW(z0, z0, lambda);
% We know that:
%   R0 == Inf
%   w0 == sqrt(z0 * lambda / pi)
%   R1 == 2 * z0
%   w1 == sqrt(2) * w0
%
% As a side note, the divergence angle of a TEM00 beam is
%   theta0 = lambda / (pi * w0) = 2 / (k * w0)
%          = sqrt(lambda / (pi * z0)) = sqrt(2 / (k * z0))
%
% see also beamZ0 and cavHG

function [R, w] = beamRW(z0, z, lambda)

  zb = z ./ z0;

  wb = z0 .* (1 + zb.^2);
  R  = wb ./ zb;
  w  = sqrt(wb * lambda / pi);
