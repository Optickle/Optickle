% mQuant = getNoiseMatrix(obj, pos, par)
%   mQuant is (Nrf * Nout) x Nnoise
%
% returns a matrix of noise vectors which correspond to
% the quantum noises which enter the Optickle system.
%
% In this, the mirror implementation, there are up to 7 loss
% points where noise enters.  Setting Lhr = 0 removes 2,
% setting Lmd = 0 removes 2, and setting Rar = 0 removes 3.
% Each disconnected input adds another noise source.

function mQuant = getNoiseMatrix(obj, pos, par)
  

  pos = pos + obj.pos;		% mirror position, with offset

  phi = -2 * par.k * pos * cos(pi * obj.aoi / 180);
  
  % Calculate noise powers for all rf components and put them in a
  % block-diagonal matrix

  % Loop over rf frequencies (which now include other wavelengths)
  mNA = []; % should pre-allocate and/or avoid loop
  for iLoop = 1:par.Nrf

      % get noise powers
      mNP = getNoiseAmp(obj.Thr, obj.Lhr, obj.Rar, obj.Lmd, phi(iLoop), ...
                                 obj.in, par.minQuant);
      
      
      mNA = blkdiag(mNA,mNP);
  end

  % these noises are unsqueezed, so make amplitude and phase
  mQuant = [mNA, 1i * mNA];
  whos
end
