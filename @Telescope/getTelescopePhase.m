% [phi, bOut] = getTelescopePhase(obj, bIn)
%   returns the Gouy phase accumulated in this telescope by
%   an input beam with basis bIn (1x2).  The output basis is
%   also computed and returned as bOut.

function [phi, bOut] = getTelescopePhase(obj, bOut)

  % compute Gouy phase
  qm = focus(OpHG, 1 ./ obj.f);
  
  df = obj.df;  
  phi = [0 0];
  for n = 1:size(df, 1)
    % add shift to focus operator
    qm = shift(qm, df(n, 1));
    
    % apply the focus-shift operator to the input basis
    bOut = apply(qm, bOut);
    
    % add the resulting Gouy phase
    phi = phi + angle(bOut - df(n, 1)) - angle(bOut);

    % compute next focus operator
    qm = focus(OpHG, 1 ./ df(n, 2));
  end

  % compute final output basis
  bOut = apply(qm, bOut);
