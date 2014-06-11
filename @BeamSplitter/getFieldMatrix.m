% getFieldMatrix method
%   returns a mOpt, the field transfer matrix for this optic
%
% mOpt = getFieldMatrix(obj, par)

function [mOpt, mDirIn, mDirOut, dldx] = getFieldMatrix(obj, pos, par)
  
  % constants
  Nrf = par.Nrf;
  Nin = 4;									% obj.Optic.Nin
  Nout = 8;									% obj.Optic.Nout
  pos = pos + obj.Optic.pos;				% mirror position
  
  % ==== Compute Coupling Matrix
  % amplitude reflectivities, transmissivities and phases
  hr = -sqrt(1 - obj.Thr - obj.Lhr);		% HR refl
  ht =  sqrt(obj.Thr);				% HR trans
  ar = -sqrt(obj.Rar);				% AR refl
  at =  sqrt(1 - obj.Rar);			% AR trans
  bt =  sqrt(1 - obj.Lmd);			% bulk trans

  % transmission combinations
  hrbt = -hr * bt;
  arbt = -ar * bt;
  htbt =  ht * bt;
  atbt =  at * bt;

  % transfer matrix
  m = zeros(Nout, Nin);

  % from front input node (in1)
  m(1, 1) = hr;
  m(2, 1) = atbt * ht;
  m(3, 1) = 0;
  m(4, 1) = atbt * hrbt * arbt * ht;

  % from back input node (in2)
  m(1, 2) = htbt * at;
  m(2, 2) = atbt * hrbt * at;
  m(3, 2) = ar;
  m(4, 2) = atbt * hrbt * arbt * hrbt * at;
  
  % B-side matrix components
  m(5:8, 3:4) = m(1:4, 1:2);

  % ==== Compute for each RF component
  % dl/dx (non-zero for reflected fields)
  d = zeros(Nout, Nin);
  caoi = cos(pi * obj.aoi / 180);
  d(1, 1) = -2 * caoi;
  d(2:4, 2) = 2 * caoi;
  d(5:8, 3:4) = d(1:4, 1:2);  % B-side

  % do all RF components
  mOpt = sparse(par.Nrf * Nout, par.Nrf * Nin);
  for n = 1:par.Nrf
    % reflection phase due to mirror position
    rp = exp(i * par.k(n) * pos * d);

    % enter this submatrix into mOpt
    nn = (1:Nout) + Nout * (n - 1);
    mm = (1:Nin) + Nin * (n - 1);
    mOpt(nn, mm) = m .* rp;
  end

  % direction matrices
  mDirIn = diag([-caoi,caoi,-caoi,caoi]);
  mDirOut = diag([-caoi,caoi,caoi,caoi,-caoi,caoi,caoi,caoi]);
  
end