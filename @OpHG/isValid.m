% b = isValid(op)
%
% true if op is a valid operator
% (use OpHG(NaN) to create an invalid operator)

function b = isValid(op)

  b = ~(any(isnan(op.x(:))) || any(isnan(op.y(:))));
  