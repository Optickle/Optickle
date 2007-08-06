% construct a block diagonal matrix with N copies of
%   the input matrix.  See also blkdiag.
%
% m = blkdiagN(m, N);

function m = blkdiagN(m0, N)
  
    tmp = cell(N, 1);
    [tmp{:}] = deal(m0);
    m = blkdiag(tmp{:});
