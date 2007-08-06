% mQuant = getNoiseMatrix(obj, pos, par)
%   mQuant is (Nrf * Nout) x Nnoise
%
% returns a matrix of noise vectors which correspond to
% the quantum noises which enter the Optickle system.
%
% In this, the source implementation, vacuum fluctuations
% are produced along with the output beam.

function mQuant = getNoiseMatrix(obj, pos, par)
  
  % noise powers
  mNP = 1;

  % convert to noise amplitudes for all RF components
  mNA = blkdiagN(sqrt(mNP), par.Nrf);
  
  % these noises are unsqueezed, so make amplitude and phase
  mQuant = [mNA, i * mNA];
