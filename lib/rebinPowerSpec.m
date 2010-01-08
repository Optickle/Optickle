% sNew = rebinSpec(fOld, sOld, fNew, useLinearInterp)
%   rebin power spectrum sOld sampled at fOld to a new power
%   spectrum sampled at fNew
%
% useLinearInterp default is false
%   loglog interpolation is used by default to make a more natural
%   looking output on the usual loglog plot.
%   This will not maintain the RMS in regions with many fNew
%   points between each fOld point (e.g., at low frequencies when
%   rebining from a linear spectrum to a log spectrum).
%

function sNew = rebinSpec(fOld, sOld, fNew, useLinearInterp)
  
  % adjust shapes
  fOld = fOld(:);
  fNew = fNew(:);
  
  if size(sOld, 1) ~= numel(fOld)
    sOld = sOld.';
  end
  if size(sOld, 1) ~= numel(fOld)
    error('frequency vector length does not match spectrum')
  end

  % numbers
  Nnew = numel(fNew);
  
  % interpolate old spectrum at new points
  sWarn = warning('off', 'MATLAB:interp1:NaNinY');  
  if nargin > 3 && useLinearInterp
    sInterp = interp1(fOld, sOld, fNew);
  else
    sInterp = exp(interp1(log(fOld), log(sOld), log(fNew)));
  end
  warning(sWarn)
  
  % mix in interpolated values
  [fAll, nSort] = sort([fNew; fOld]);
  [nn, nMap] = sort(nSort);
      
  % loop over spectra
  sNew = zeros(Nnew, 1);
  for m = 1:size(sOld, 2)
    sAll = [sInterp(:, m); sOld(:, m)];
    sAll = sAll(nSort);
    
    % loop over points
    for n = 1:Nnew
      % integrate under bins
      if n == 1
        nn = 1:nMap(n);
        df = fNew(n) - fAll(1);           % bin width
      else
        nn = nMap(n - 1):nMap(n);
        df = fNew(n) - fNew(n - 1);       % bin width
      end
      
      pNew = trapz(fAll(nn), sAll(nn));   % integrated power
      sNew(n, m) = pNew / df;
      
    end
  end
  
%   % plot
%   loglog(fOld, sqrt(sOld), fNew, sqrt(sNew))
%   hold on
%   loglog(fOld, ampSpectrumRMS(fOld, sqrt(sOld)), ...
%          fNew, ampSpectrumRMS(fNew, sqrt(sNew)), ...
%          'LineStyle', '--')
%   hold off
%   grid on
  
end
