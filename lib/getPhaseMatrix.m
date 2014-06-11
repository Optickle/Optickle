% phase matrix for tickle and sweep
%
% mPhi = getPhaseMatrix(vLen, vFreq, [vPhiLinks], [mPhiFrf])
% vPhiLinks is an additional (positive) phase for each link at all frequencies (Nlink x 1)
% mPhiFrf is an additional (positive) phase for each RF frequency (Nlink x Nrf)

function mPhi = getPhaseMatrix(vLen, vFreq, vPhiLinks, mPhiFrf)
  
  % vPhiLinks is an additional (positive) phase for each link at all frequencies (Nlink x 1)
  % mPhiFrf is an additional (positive) phase for each RF frequency (Nlink x Nrf)

  Nlink = numel(vLen);
  Nrf = numel(vFreq);
  
  if nargin < 3 || isempty(vPhiLinks)
      vPhiLinks = zeros(Nlink,1);
  end
  
  if nargin < 4 || isempty(mPhiFrf)
      mPhiFrf = zeros(Nlink,Nrf);
  end
  
  v = exp(1i * (vLen(:) * vFreq(:).'...
                + repmat(vPhiLinks, 1, Nrf)...
                + mPhiFrf...
               )... % close phases
         ); % close exp

  N = numel(v(:));
  mPhi = sparse(1:N, 1:N, v(:), N, N);
