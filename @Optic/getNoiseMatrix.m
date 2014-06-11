% mQuant = getNoiseMatrix(obj, pos, par)
%   mQuant is (Nrf * Nout) x Nnoise
%
% returns a matrix of noise vectors which correspond to
% the quantum noises which enter the Optickle system.
%
% In this, the default implementation, Nnoise = 0.

function mQuant = getNoiseMatrix(obj, pos, par)
  
  % default is no noise
  mQuant = zeros(2 * par.Nrf * obj.Nout, 0);
end
