% phase matrix for tickle and sweep
%
% mPhi = getPhaseMatrix(vLen, vFreq)

function mPhi = getPhaseMatrix(vLen, vFreq, vPhiGouy)
  
  if nargin == 2
    v = exp(1i * vLen(:) * vFreq(:)');
  else
    Nrf = numel(vFreq);
    v = exp(1i * (vLen(:) * vFreq(:)' - repmat(vPhiGouy, 1, Nrf)));
  end
  N = numel(v(:));
  mPhi = sparse(1:N, 1:N, v(:), N, N);
