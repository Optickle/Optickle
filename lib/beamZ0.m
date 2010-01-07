% [z0, z] = beamZ0(R, w, lambda)
%
% lambda - laser wavelength
% R - wave front radius of curvature
% w - beam radius at a beam cross-section (1/e^2 in power)
% z0 - Rayleigh Range of the beam
% z - distance past the waist of this beam cross-section
%
% Some trivia... Given the following:
%   [z0, z] = beamHG(Inf, w0, lambda);
% We know that:
%   z0 == w0^2 * pi / lambda
%   z == 0
%
% see also beamRW and cavHG

function [z0, z] = beamZ0(R, w, lambda)

  wb = w.^2 * pi / lambda;

  zb = wb ./ R;
  z0 = wb ./ (1 + zb.^2);
  z = zb * z0;

end
