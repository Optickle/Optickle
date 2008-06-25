% sNew = rebinSpec(f, s, fNew)
%   rebin a power spectrum
%
% The values in the spectrum are assumed to represent the
% integrated power from the previous point to that point:
%  s(n) = integral of power(f) from f(n - 1) to f(n) / (f(n) - f(n-1))
%
% The first point is the integrated power from DC:
%  s(1) = integral of power(f) from 0 to f(1) / f(1)

function sNew = rebinSpec(f, s, fNew)
  
  % adjust shapes
  f = f(:)';
  fNew = fNew(:)';
  
  % add point at DC
  if f(1) == 0
    fOld = f;
    sOld = s;
  else
    fOld = [0, f];
    sOld = [0, s];
  end
  
  % compute power in each bin
  df = diff(fOld);

  Nold = numel(fOld);
  pOld = zeros(1, Nold);
  pOld(2:end) = sOld(2:end) .* df;

  % add end point
  if fNew(end) > f(end)
    fOld(end + 1) = fNew(end);
    pOld(end + 1) = 0;
    sOld(end + 1) = 0;
  end
  
  % loop initial conditions
  Nnew = numel(fNew);
  pNew = zeros(1, Nnew);
  
  m = 1;          % start at first frequency point
  fLast = 0;      % with previous frequency at zero
  sLast = pOld(2) / fOld(2);      % current slope

  for n = 1:Nnew
    if fOld(m + 1) >= fNew(n)
      % still before next bin, use current slope
      pNew(n) = sLast * (fNew(n) - fLast);
      fLast = fNew(n);
    else
      % move to next bin
      m = m + 1;
      pSum = sLast * (fOld(m) - fLast);

      % accumulate power in covered bins
      while fOld(m + 1) < fNew(n)
        m = m + 1;
        pSum = pSum + pOld(m);
      end
      
      % add fraction of last bin
      sLast = sOld(m + 1);
      pNew(n) = pSum + sLast * (fNew(n) - fOld(m));
      fLast = fNew(n);
    end    
  end
  
  % make spectral density
  df = diff(fNew);

  sNew = zeros(1, Nnew);
  sNew(2:end) = pNew(2:end) ./ df;
  
  % do first new point
  if fNew(1) ~= 0
    sNew(1) = pNew(1) / fNew(1);
  else
    if f(1) == 0
      sNew(1) = s(1);
    else
      sNew(1) = 0;
    end
  end
