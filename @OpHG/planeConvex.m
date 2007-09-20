% mop = planeConvex(op, aoi, crv, ior)
%
% This function generates a matrix of operators which represents a
% plano-convex mirror or lens.  The matrix is 4x2, with the 2
% inputs being the front and back of the optic, and the 4 outputs
% being the reflected and transmitted fields.
%
% Operator matrix arrangment is:
% col (inputs): 1 == front, 2 == back
% row (outputs): 1 == front main, 2 = back main,
%                3 == back pick-off, 4 = front pick-off
%
% Arguments:
% op = input operator for all fields (usually empty)
% aoi = angle of incidence
% crv = 1 / radius of curvature
% ior = index of refraction
%
%% Example:
% opPCX = planeConvex(OpHG, 45, 1 / 20e3, 1.45);

function mop = planeConvex(op, aoi, crv, ior)

  % operator matrix  
  mop = repmat(OpHG(NaN), 4, 2);
  
  % inverse focal lengths
  sinFront = sin(pi * aoi / 180);
  cosFront = cos(pi * aoi / 180);
  cosBack = sqrt(1.0 - (sinFront / ior)^2);

  crx = crv * 2.0 / cosFront;
  cry = crv * 2.0 * cosFront;
  ctx = crv * (ior - cosFront / cosBack);
  cty = crv * cosFront * (ior - 1.0);

  % basis operators
  nop = OpHG;					% no op
  fop = focus(nop, crx, cry);			% front refl
  bop = focus(nop, -ior * crx, -ior * cry);	% back refl
  top = focus(nop, -ctx, -cty);			% transmission

  % from front input node (in1)
  %   no route to back pick-off: mop(3, 1) left invalid
  mop(1, 1) = fop * op;
  mop(2, 1) = top * op;
  mop(4, 1) = bop * top * op;

  % from back input node (in2)
  %   planar reflection to back pick-off: mop(3, 1) == op
  mop(1, 2) = top * op;
  mop(2, 2) = bop * op;
  mop(3, 2) = op;
  mop(4, 2) = bop * bop * op;
