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
  
  % optic parametes as vectors for each field component
  [vThr, vLhr, vRar, vLmd] = obj.getVecProperties(par.lambda, par.pol);

  % Calculate noise powers for all rf components and put them in a
  % block-diagonal matrix

  % Loop over rf frequencies (which now include other wavelengths)
  mNA = []; % should pre-allocate index in for more speed
  for n = 1:par.Nrf

      % get noise powers
      mNP = Mirror.getNoiseAmp(vThr(n), vLhr(n), vRar(n), ...
        vLmd(n), phi(n), vin, par.minQuant);
      
      % iteratively build a block diagonal matrix
      mNA = blkdiag(mNA, sqrt(mNP));
  end

  % these noises are unsqueezed, so make amplitude and phase
  mQuant = blkdiag(mNA, mNA);
end
