% rms = ampSpectrumRMS(freq, noiseAmp)
%
% freq = frequency vector (N x 1)
% noiseAmp = noise amplitude spectrum (N x M)
%
% rms = cumulative RMS starting at high frequency (N x M)

function rms = ampSpectrumRMS(f, noiseAmp)

  % adjust shapes
  if ~isvector(f)
    error('f must be a vector')
  end
  
  isTranspose = size(f, 2) ~= 1;
  
  f = f(:);
  if isTranspose
    noiseAmp = noiseAmp.';
  end
  
  if size(noiseAmp, 1) ~= numel(f)
    error('frequency vector length does not match spectrum')
  end
  
  % number of spectra
  M = size(noiseAmp, 2);
  
  % loop over spectra
  fRev = f(end:-1:1);
  rms = zeros(size(noiseAmp));
  for n = 1:M
    % cumulative rms values
    % (use -fRev to force x-axis to be ascending order)
    rmsRev = sqrt(cumtrapz(-fRev, noiseAmp(end:-1:1, n).^2));
  
    % reverse
    rms(:, n) = rmsRev(end:-1:1, :);
  end

  % transpose output, if requested
  if isTranspose
    rms = rms.';
  end

end
