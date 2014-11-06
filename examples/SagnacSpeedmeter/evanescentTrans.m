% evanescent wave transmission
%
% --- From ---
% Frustrated total internal reflection: A demonstration and review
% S. Zhu, A. W. Yu, D. Hawley, and R. Roy
% Citation: American Journal of Physics 54, 601 (1986)
%   doi: 10.1119/1.14514
% View online: http://dx.doi.org/10.1119/1.14514


function [Ts, Tp] = evanescentTrans(nFrom, nGap, nTo, dGap, phi)

  % prepare some variables
  nTF = nTo ./ nFrom;
  nFG = nFrom ./ nGap;
  
  nTF2 = nTF.^2;
  nFG2 = nFG.^2;
  
  sp = sind(phi);
  sp2 = sp.^2;
  
  cp = cosd(phi);
  cp2 = cp.^2;
  
  ss = sqrt(nTF2 - sp2);
  
  %%%%%%%%%%%%%
  % compute alpha and beta
  
  % perpendicular (S-pol)
  alphaS = (nFG2 - 1) .* (nTF2 .* nFG2 - 1) ./ ...
    (4 * nFG2 .* cp .* (nFG2 .* sp2 - 1) .* ss);
  
  betaS = (ss + cp).^2 ./ (4 * cp .* ss);
  
  % parallel (P-pol)
  alphaP = (alphaS ./ nTF2) .* ((nFG2 + 1) .* sp2 - 1) .* ...
    ((nTF2 .* nFG2 + 1) .* sp2 - nTF2);
  betaP = (ss + nTF2 .* cp).^2 / (4 * nTF2 .* cp .* ss);
  
  %%%%%%%%%%%%%
  % finalize computation
  
  y = 2 * pi * dGap .* sqrt(nFrom.^2 .* sp2 - nGap.^2);
  
  Ts = 1 ./ (alphaS .* sinh(y).^2 + betaS);
  Tp = 1 ./ (alphaP .* sinh(y).^2 + betaP);
  
end

