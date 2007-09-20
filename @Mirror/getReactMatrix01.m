% getReactMatrix method for TEM01 mode (pitch)
%   returns a Ndrive x (Nrf * Nin) x Naf matrix
%
% HACK: using the TEM00 mechTF
%
% mDrv = getReactMatrix01(obj, pos, vBasis, par)

function mRct = getReactMatrix01(obj, pos, vBasis, par, mOpt, d)
  
  % check for optional arguments
  if nargin < 5
    [mOpt, d] = getFieldMatrix(obj, pos, par);
  end
  
  % constants
  Nrf = par.Nrf;
  Naf = par.Naf;
  Nin = 2;						% obj.Optic.Nin
  Nout = 4;						% obj.Optic.Nout

  % mechanical response
  rsp = getMechResp(obj, par.vFaf, 2);
  
  % output basis, where the basis is undefined, put z = 0, z0 = 1
  vBout = apply(getBasisMatrix(obj), vBasis);
  vBout(~isfinite(vBout)) = i;
  
  % mirror TEM01 mode reaction torque scales with beam size
  %   torque = w * (A01 * A00)
  % so here the reaction is proportional to waist size
  %   w = sqrt(z0 * (1 + (z/z0)^2)) * sqrt(2 / k)
  % The sqrt(2 / k) part is done separately for each RF component
  % the sqrt(z0 * (1 + (z/z0)^2)) is done for each link using the
  % the waist size matrix, mW, is computed below.
  %
  %   the y-basis, vBout(:,2), is of interest for the vertical 01 mode
  z = real(vBout(:,2));
  z0 = imag(vBout(:,2));
  mW = diag(sqrt(z0 .* (1 + (z ./ z0).^2)));
  
  % field matrix and derivatives
  mRct = zeros(1, Nrf * Nin, Naf);
  for nAF = 1:Naf
    for n = 1:Nrf
      % reflection reaction coefficient
      dr = mW * sqrt(2 / par.k(n)) * d;
    
      % enter this submatrix into mRct
      nn = (1:Nout) + Nout * (n - 1);
      mm = (1:Nin) + Nin * (n - 1);
      mRct(1, mm, nAF) = rsp(nAF) * sum(abs(mOpt(nn, mm)).^2 .* dr, 1);
    end
  end
