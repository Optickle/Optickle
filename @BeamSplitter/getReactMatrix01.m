% getReactMatrix method for TEM01 mode
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
  Nin = 4;						% obj.Optic.Nin
  Nout = 8;						% obj.Optic.Nout

  % mechanical response
  rsp = getMechResp(obj, par.vFaf, 2);
  
  % output basis, where the basis is undefined, put z = 0, z0 = 1
  vBout = apply(getBasisMatrix(obj), vBasis);
  vBout(~isfinite(vBout)) = i;
  
  % mirror TEM01 mode reaction matrix (see @Mirror/getReactMatrix01)
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
