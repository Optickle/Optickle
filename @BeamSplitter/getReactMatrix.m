% getReactMatrix method
%   returns a Ndrive x (Nrf * Nin) x Naf matrix
%
% mDrv = getReactMatrix(obj, pos, par)

function mRct = getReactMatrix(obj, pos, par, mOpt, d)
  
  % check for optional arguments
  if nargin < 4
    [mOpt, d] = getFieldMatrix(obj, pos, par);
  end
  
  % constants
  Nrf = par.Nrf;
  Naf = par.Naf;
  Nin = 4;							% obj.Optic.Nin
  Nout = 8;							% obj.Optic.Nout

  % mechanical response
  rsp = getMechResp(obj, par.vFaf);
  
  % field matrix and derivatives
  mRct = zeros(1, Nrf * Nin, Naf);
  for nAF = 1:Naf
    for n = 1:Nrf
      % enter this submatrix into mRct
      nn = (1:Nout) + Nout * (n - 1);
      mm = (1:Nin) + Nin * (n - 1);
      mRct(1, mm, nAF) = rsp(nAF) * sum(abs(mOpt(nn, mm)).^2 .* d, 1);
    end
  end
