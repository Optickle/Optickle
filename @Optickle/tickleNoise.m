% backend for tickle and tickle01 shot noise calculation
%
% [Nnoise, mQuant, shotPrb] = tickleShot(opt, prbList, vDC, mQuant)

function [mQuant, shotPrb] = tickleNoise(opt, prbList, vDC, mQuant)

  % set the quantum scale
  pQuant  = Optickle.h * opt.nu;
  aQuant = sqrt(pQuant);
  aQuantTemp = repmat(aQuant.',opt.Nlink,1); % aQuant is
                                             % Nrfx1. mQuant is
                                             % Nlink*Nrf x number
                                             % of loss points*2

  % get both upper and lower sidebands
  aQuantMatrix = diag([aQuantTemp(:);aQuantTemp(:)]); 
  mQuant = aQuantMatrix * mQuant;
  
  % compile probe shot noise vector
  shotPrb = zeros(opt.Nprobe, 1);
  
  for k = 1:opt.Nprobe
    mIn_k = prbList(k).mIn;
    mPrb_k = prbList(k).mPrb;
    
    % This section attempts to account for the shot noise due to
    % fields which are not recorded by a detector. E.g. a 10
    % MHz detector will not see signal due to 37 MHz sidebands
    % but it should see their shot noise
    
    % Define a new vDCin which includes the appropriate pQuant
    % for each dc component
    vDCinShot = mIn_k * vDC;
    
    shotPrb(k) = (1 - sum(abs(mPrb_k), 1)) * ...
      (pQuant .* abs(vDCinShot).^2);
  end
end
