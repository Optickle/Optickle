% phase matrix for tickle and sweep
%
% mPhi = getPhaseMatrix(vLen, vFreq)

function mPhi = getPhaseMatrix(vLen, vFreq)
  
  v = exp(i * vLen(:) * vFreq(:)');
  N = length(v(:));
  mPhi = sparse(1:N, 1:N, v(:), N, N);
