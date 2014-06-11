% mQuant = getNoiseMatrix(obj, pos, par)
%   mQuant is (Nrf * Nout) x Nnoise
%
% returns a matrix of noise vectors which correspond to
% the quantum noises which enter the Optickle system.
%
% In this, the squeezer implementation, there is 1 loss
% point where noise enters.  This loss = 1-escape_efficiency 

function mQuant = getNoiseMatrix(obj, pos, par)
  
  % noise powers
  loss = obj.loss;
  if loss > par.minQuant
    mNP = loss;
  else
    mNP = zeros(1, 0);
    loss = 0;
  end
  if obj.in == 0
    mNP = [mNP, 1 - loss];
  end
  
  % convert to noise amplitudes for all RF components
  mQuant = blkdiagN(sqrt(mNP), 2*par.Nrf);
end