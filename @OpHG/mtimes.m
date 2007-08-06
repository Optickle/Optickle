% produce of operators
%
% op = mtimes(opLHS, opRHS)

function op = mtimes(op, opRHS)

  op.x = op.x * opRHS.x;
  op.y = op.y * opRHS.y;
