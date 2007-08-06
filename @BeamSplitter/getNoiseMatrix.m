% mQuant = getNoiseMatrix(obj, pos, par)
%   mQuant is (Nrf * Nout) x Nnoise
%
% returns a matrix of noise vectors which correspond to
% the quantum noises which enter the Optickle system.
%
% The BeamSplitter is a combination of 2 mirrors, so it has
% up to 14 internal loss points.  See @Mirror/getNoiseMatrix.

function mQuant = getNoiseMatrix(obj, pos, par)
  
  % get noise powers
  mNPa = getNoisePower(obj.Thr, obj.Lhr, obj.Rar, obj.Lmd, ...
    obj.Optic.in(1:2), par.minQuant);
  mNPb = getNoisePower(obj.Thr, obj.Lhr, obj.Rar, obj.Lmd, ...
    obj.Optic.in(3:4), par.minQuant);
  mNP = blkdiag(mNPa, mNPb);
  
  % convert to noise amplitudes for all RF components
  mNA = blkdiagN(sqrt(mNP), par.Nrf);
  
  % these noises are unsqueezed, so make amplitude and phase
  mQuant = [mNA, i * mNA];
