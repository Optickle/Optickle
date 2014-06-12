function m = blkdiagN(m0, N)
  % construct a block diagonal matrix with N copies of
  %   the input matrix.  See also blkdiag.
  %
  % m = blkdiagN(m, N);
  
  % prepare an N element cell array
  tmp = cell(N, 1);
  
  % fill all N elements with the input matrix
  [tmp{:}] = deal(m0);
  
  % make a block diagonal matrix with these matrices
  m = blkdiag(tmp{:});
end
