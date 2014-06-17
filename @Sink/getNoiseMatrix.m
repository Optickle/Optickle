% mQuant = getNoiseMatrix(obj, pos, par)
%   mQuant is (Nrf * Nout) x Nnoise
%
% returns a matrix of noise vectors which correspond to
% the quantum noises which enter the Optickle system.
%
% In this, the sink implementation, there is 1 loss
% point where noise enters.
% A disconnected input adds another noise source.

function mQuant = getNoiseMatrix(obj, pos, par)
  
  % noise powers
  loss = obj.loss;
  if loss > par.minQuant
    mQuant = diag(sqrt(loss * Optickle.h * [par.nu; par.nu]));
  else
    mQuant = zeros(2 * par.Nrf, 0);
  end
end
