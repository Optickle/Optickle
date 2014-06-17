% mQuant = getNoiseMatrix(obj, pos, par)
%   mQuant is (Nrf * Nout) x Nnoise
%
% returns a matrix of noise vectors which correspond to
% the quantum noises which enter the Optickle system.
%
% In this, the source implementation, vacuum fluctuations
% are produced along with the output beam.

function mQuant = getNoiseMatrix(obj, pos, par)
  
  % unity noise amplitudes for all RF components (upper and lower ASBs)
  mQuant = diag(sqrt(Optickle.h * [par.nu; par.nu]));
end
