% rms = ampSpectrumRMS(freq, noiseAmp)
%
% freq = frequency vector (N x 1)
% noiseAmp = noise amplitude spectrum (N x M)
%
% rms = cumulative RMS starting at high frequency (N x M)

function rms = ampSpectrumRMS(f, noiseAmp)

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

end
