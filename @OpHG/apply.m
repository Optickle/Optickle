% apply this OpHG to a complex basis (2 complex numbers)
%  or vector of bases (Nx2 or 2xN complex vector)

function q = apply(op, q)

  if size(q, 2) == 2
    q(:, 1) = applySingle(op.x, q(:, 1)')';
    q(:, 2) = applySingle(op.y, q(:, 2)')';
  elseif size(q, 1) == 2
    q(1, :) = applySingle(op.x, q(1, :));
    q(2, :) = applySingle(op.y, q(2, :));
  else
    error('Basis vector must be Nx2 or 2xN')
  end
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% apply a single operator
function q = applySingle(op, q)
    q = op * [q; ones(size(q))];
    q = q(1, :) ./ q(2, :);
