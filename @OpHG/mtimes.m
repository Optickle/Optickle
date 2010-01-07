% product of operators
%
% op = mtimes(opLHS, opRHS)

function op = mtimes(op, opRHS)

  if numel(op) == 1 && numel(opRHS) == 1
    % simple case
    op.x = op.x * opRHS.x;
    op.y = op.y * opRHS.y;
  elseif size(opRHS, 1) == size(op, 2)
    opLHS = op;
    N = size(opLHS, 1);
    M = size(opRHS, 2);
    P = size(opRHS, 1);
    
    op = repmat(OpHG(NaN), N, M);
    for n = 1:N
      for m = 1:M
	for p = 1:P
	  opX = opLHS(n, p).x * opRHS(p, m).x;
	  opY = opLHS(n, p).y * opRHS(p, m).y;
	  
	  % X basis check
	  if any(any(isfinite(op(n, m).x)))
	    % already have a result... are they the same?
	    if any(any(isfinite(opX))) && ...
		any(any(abs((op(n, m).x - opX)./opX) > 0.01))
	      warning('Operator result ambiguity for element X %d, %d', ...
		n, m);
	    end
	  else
	    op(n, m).x = opX;
	  end
	  
	  % Y basis check
	  if any(any(isfinite(op(n, m).y)))
	    % already have a result... are they the same?
	    if any(any(isfinite(opY))) && ...
		any(any(abs((op(n, m).y - opY)./opY) > 0.01))
	      warning('Operator result ambiguity for element Y %d, %d', ...
		n, m);
	    end
	  else
	    op(n, m).y = opY;
	  end
	end
      end
    end
  else
    error('Size mismatch... cannot multiply.')
  end
  
end
