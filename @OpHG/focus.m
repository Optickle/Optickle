% Make an OpHG for a focusing element
%   returns op = focus_operator * op
%
% The focus parameter is the curvature induced by this element.
% For a curved optic in vacuum, the curvature induced
% by transmission through each surface is
%   crv = (n - 1) / R
% where n is the index of refraction, and R the radius of
% curvature.  For reflection from a curved optic,
%   crv = -2 / R
% And for a lens with focal length f
%   crv = 1 / f
%
% A radially symmetric optic can be specified with only one curvature
% op = focus(curv)
%
% Curvatures can also be specified independently
% op = focus(curvX, curvY)

function op = focus(op, curvX, curvY)

  if nargin == 2
    curvY = curvX;
  end

  op.x = [1, 0; -curvX, 1] * op.x;
  op.y = [1, 0; -curvY, 1] * op.y;
