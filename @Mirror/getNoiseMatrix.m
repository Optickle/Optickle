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
  

  pos = pos + obj.Optic.pos;		% mirror position, with offset
  phi = -2 * (2 * pi / par.lambda) * pos * cos(pi * obj.aoi / 180);
  
  % get noise powers
  mNP = getNoiseAmp(obj.Thr, obj.Lhr, obj.Rar, obj.Lmd, phi, ...
    obj.Optic.in, par.minQuant);

  % convert to noise amplitudes for all RF components
  mNA = blkdiagN(mNP, par.Nrf);
  
  % these noises are unsqueezed, so make amplitude and phase
  mQuant = [mNA, i * mNA];
