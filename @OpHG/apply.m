% apply this OpHG to a complex basis (2 complex numbers)
%  or vector of bases (Nx2 complex vector)
%
% A complex basis is given by the distance past the waist
% (z) and the Rayleigh Range of the beam (z0), such that
% q = z + i * z0
%
% see also beamZ0, beamRW and cavHG

function q = apply(op, q)

  % deal with matrix operators
  if numel(op) > 1
    N = size(op, 1);
    M = size(q, 1);
    if M ~= size(op, 2)
      error('Operator and basis vector inner dimention mismatch');
    end
    
    vBout = NaN(N, 2);
    for n = 1:N
      for m = 1:M
	if ~any(isfinite(vBout(n, :)))
	  vBout(n, :) = apply(op(n, m), q(m, :));
	end
      end
    end
    q = vBout;
    return
  end

  % single operator
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
