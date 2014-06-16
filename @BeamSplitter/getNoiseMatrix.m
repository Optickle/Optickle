% mQuant = getNoiseMatrix(obj, pos, par)
%   mQuant is (Nrf * Nout) x Nnoise
%
% returns a matrix of noise vectors which correspond to
% the quantum noises which enter the Optickle system.
%
% The BeamSplitter is a combination of 2 mirrors, so it has
% up to 14 internal loss points.  See @Mirror/getNoiseMatrix.

function mQuant = getNoiseMatrix(obj, pos, par)
  
  % compute phases for getNoiseAmp
  pos = pos + obj.pos;		% mirror position, with offset
  phi = -2 * par.k * pos * cos(pi * obj.aoi / 180);
  
  % optic parametes as vectors for each field component
  [vThr, vLhr, vRar, vLmd] = obj.getVecProperties(par.lambda, par.pol);

  % Calculate noise powers for all rf components and put them in a
  % block-diagonal matrix

  % Loop over rf frequencies (which now include other wavelengths)
  mNA = []; % should pre-allocate index in for more speed
  for n = 1:par.Nrf

      % get noise powers, in 1 and 2
      mNPa = Mirror.getNoiseAmp(vThr(n), vLhr(n), vRar(n), ...
        vLmd(n), phi(n), obj.in(1:2), par.minQuant);
      
      % get noise powers, in 3 and 4
      mNPb = Mirror.getNoiseAmp(vThr(n), vLhr(n), vRar(n), ...
        vLmd(n), phi(n), obj.in(3:4), par.minQuant);
      
      % iteratively build a block diagonal matrix
      mNA = blkdiag(mNA, sqrt(blkdiag(mNPa, mNPb)));
  end

  % these noises are unsqueezed, so make amplitude and phase
  mQuant = blkdiag(mNA, mNA);

end