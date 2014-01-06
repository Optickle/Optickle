% mQuant = getNoiseMatrix(obj, pos, par)
%   mQuant is (Nrf * Nout) x Nnoise
%
% returns a matrix of noise vectors which correspond to
% the quantum noises which enter the Optickle system.
%
% The BeamSplitter is a combination of 2 mirrors, so it has
% up to 14 internal loss points.  See @Mirror/getNoiseMatrix.

function mQuant = getNoiseMatrix(obj, pos, par)
  
  pos = pos + obj.Optic.pos;		% mirror position, with offset
  phi = -2 * (2 * pi / par.lambda) * pos * cos(pi * obj.aoi / 180);

  % get noise powers
  mNPa = getNoiseAmp(obj.Thr, obj.Lhr, obj.Rar, obj.Lmd, phi, ...
    obj.Optic.in(1:2), par.minQuant);
  mNPb = getNoiseAmp(obj.Thr, obj.Lhr, obj.Rar, obj.Lmd, phi, ...
    obj.Optic.in(3:4), par.minQuant);
  mNP = blkdiag(mNPa, mNPb);
  
  % convert to noise amplitudes for all RF components
  mNA = blkdiagN(mNP, par.Nrf);
  
  % these noises are unsqueezed, so make amplitude and phase
  mQuant = [mNA, i * mNA];
