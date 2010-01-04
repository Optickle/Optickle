% vNoiseOut = convNoise(vNoiseA, vNoiseB)
%   convolution of 2 noise spectra
%

function [vNoiseOut, fLin, linAB] = convNoise(f, dfLin, vNoiseA, vNoiseB)
  
  % sizes of things
  Nf = numel(f);
  Na = size(vNoiseA, 1);
  Nb = size(vNoiseB, 1);
  
  if Nf ~= size(vNoiseA, 2)
    error('Size mismatch.  size(vNoiseA, 2) = %d ~= %d = numel(f)', ...
      size(vNoiseA, 2), Nf);
  end
  if Nf ~= size(vNoiseB, 2)
    error('Size mismatch.  size(vNoiseB, 2) = %d ~= %d = numel(f)', ...
      size(vNoiseB, 2), Nf);
  end
  if Na ~= 1 && Nb ~= 1 && Na ~= Nb
    error('Size mismatch.  size(vNoiseA, 1) = %d ~= %d = size(vNoiseB, 1)', ...
      size(vNoiseA, 1), size(vNoiseB, 1));
  end
  
  % frequency for linear resample with linear spacing
  fLin = 0:dfLin:f(end);
  NfLin = numel(fLin);
  
  % convolve
  if Na == 1
    % rebin A
    linA = rebinSpec(f, vNoiseA, fLin);
    
    % compute for each B
    linAB = zeros(Nb, NfLin);
    for n = 1:Nb
      % rebin B
      linB = rebinSpec(f, vNoiseB(n, :), fLin);
      
      % convolve
      linAB(n, :) = convAB(linA, linB, dfLin);
    end
  elseif Nb == 1
    % rebin B
    linB = rebinSpec(f, vNoiseB, fLin);
    
    % compute for each A
    linAB = zeros(Na, NfLin);
    for n = 1:Na
      % rebin A
      linA = rebinSpec(f, vNoiseA(n, :), fLin);
      
      % convolve
      linAB(n, :) = convAB(linA, linB, dfLin);
    end
  else
    % compute for each pair
    linAB = zeros(Na, NfLin);
    for n = 1:Na
      linA = rebinSpec(f, vNoiseA(n, :), fLin);
      linB = rebinSpec(f, vNoiseB(n, :), fLin);
      linAB(n, :) = convAB(linA, linB, dfLin);
    end
  end
 
  % rebin back to original frequency vector
  Nout = size(linAB,1);
  vNoiseOut = zeros(Nout, Nf);
  for n = 1:Na
    vNoiseOut(n, :) = rebinSpec(fLin, linAB(n, :), f);
  end
  
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function linAB = convAB(linA, linB, df)
  
  % make double sided spectra
  dblA = [linA(1, end:-1:1), 0, linA] / 2;
  dblB = [linB(1, end:-1:1), 0, linB] / 2;

  % convolve
  dblAB = conv(dblA, dblB);
  
  % convert back to single sided
  Nf = numel(linA);
  n = (1:Nf) + 2 * (Nf - 1);
  linAB = dblAB(n) * df * 2;
  
end
