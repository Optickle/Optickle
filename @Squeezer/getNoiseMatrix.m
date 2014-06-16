% mQuant = getNoiseMatrix(obj, pos, par)
%   mQuant is (Nrf * Nout) x Nnoise
%
% returns a matrix of noise vectors which correspond to
% the quantum noises which enter the Optickle system.
%
% In this, the squeezer implementation, there is 1 loss
% point where noise enters.  This loss = 1-escape_efficiency 
% Sidebands are added only for the Wavelength, RF frequency, and
% polarization which is squeezed by the Squeezer.  

function mQuant = getNoiseMatrix(obj, pos, par)
  
  % noise powers
  loss = 1-obj.escEff;
  if loss > par.minQuant
    mNP = loss;
  else
    mNP = zeros(1, 0);
    loss = 0;
  end
  
  %Find the RF component which is squeezed
  [freqMatch, freqClose] = isSameFreq(obj.fRF*ones(size(par.nu)), par.nu);
  samePol = obj.pol*ones(size(par.pol))==par.pol;
  RFMat =  freqMatch & samePol;
  
  %Warning message of zero or n>1 RF components are squeezed
  if nnz(RFMat)==0
      warning('No RF components are being squeezed! ');
  elseif nnz(RFMat)>1
     warning('More than one RF component is being squeezed!'); 
  end
  
  % convert to noise amplitudes for correct RF components
  % all other components have zero added noise amplitude
  mQuant = blkdiag(sqrt(mNP)*RFMat, sqrt(mNP)*RFMat);
  