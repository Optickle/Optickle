% [z0, z1, z2] = cavHG(L, R1, R2)
%
% L - length of the cavity
% R1 - radius of curvature of the first mirror
% R2 - radius of curvature of the second mirror
% z0 - Rayleigh Range of the beam
% z1 - distance the first mirror is past the waist
%      (negative if the waist is inside the cavity)
% z2 - distance the second mirror is past the waist (z2 = L + z1)
%
% The sign convention is such that basis leaving the first
% mirror is [z0, z1], and the basis arriving at the second
% mirror is [z0, z2].
%
% see also beamZ0 and beamRW


function [z0, z1, z2] = cavHG(L, R1, R2)

  if R1 == Inf
    LR2 = R2 - L;

    z0 = sqrt(L * LR2);
    z1 = 0;
    z2 = L;
  elseif R2 == Inf
    LR1 = R1 - L;

    z0 =  sqrt(L * LR1);
    z1 = -L;
    z2 =  0;
  else
    LR1 = R1 - L;
    LR2 = R2 - L;
    LRR = LR1 + LR2;

    z0 =  sqrt(L * LR1 * LR2 * (R1 + R2 - L)) / abs(LRR);
    z1 = -L * LR2 / LRR;
    z2 =  L * LR1 / LRR;
  end
  