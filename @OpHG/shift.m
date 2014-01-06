% Make an OpHG for a position shift
%   returns op = shift_operator(dz) * op
%
% A position shift operation is more something done to
% the observer than to the beam, but in any case it is
% needed to compute telescopes as the focusing elements
% are located at different places along the beam path.
%
% op = shift(op, dz)

function op = shift(op, dz)

  m = [1, dz; 0, 1];
  op.x = m * op.x;
  op.y = m * op.y;
