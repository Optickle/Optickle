% hNew = interpLogLog(fOld, hOld, fNew)
%
%   linear interpolation in loglog space
%
%   complex arguments have their magnitude interpolated
%   in loglog space, and their phase interpolated in
%   semilogx space.  This should work for transfer functions.

function hNew = interpLogLog(fOld, hOld, fNew)

  % adjust shapes
  if ~isvector(fOld)
    error('fOld must be a vector')
  end
  if ~isvector(fNew)
    error('fNew must be a vector')
  end
  
  isOldTranspose = size(fOld, 2) ~= 1;
  isNewTranspose = size(fNew, 2) ~= 1;
  
  fOld = fOld(:);
  fNew = fNew(:);  
  if isOldTranspose
    hOld = hOld.';
  end
  
  if size(hOld, 1) ~= numel(fOld)
    error('frequency vector length does not match amplitude vector')
  end

  % complex log of hNew
  logNew = interp1(log(fOld), log(hOld), log(fNew));

  % new complex vector
  hNew = exp(logNew);
  
  % force real inputs to give real outputs
  if all(isreal(hOld))
    hNew = real(hNew);
  end
  
  % transpose output if requested by input vector
  if isNewTranspose
    hNew = hNew.';
  end

end

%%%%%%%%%%%%%%%%%%%%%%%
% Old implementation
%%%%%%%%%%%%%%%%%%%%%%%

%   % log frequency vectors
%   logFold = log(fOld);
%   logFnew = log(fNew);
%   
%   % new log magnitude
%   logMagNew = interp1(logFold, log(abs(hOld)), logFnew);
%   
%   % new angles
%   dAngleOld = zeros(size(fOld));
%   dAngleOld(2:end) = diff(angle(hOld));
%   angleOld = cumsum(dAngleOld) + angle(hOld(1)); % unwrapped angle
%   
%   angleNew = interp1(logFold, angleOld, logFnew);
  
