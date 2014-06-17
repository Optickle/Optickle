% getFieldMatrix method
%   returns a mOpt, the field transfer matrix for this optic
%
% [mOpt, mDirIn, mDirOut, dldx] = getFieldMatrix(obj, pos, par)

function [mOpt, mDirIn, mDirOut, dldx] = getFieldMatrix(obj, pos, par)
  
  % constants
  Nrf = par.Nrf;
  Nin = 4;									% obj.Optic.Nin
  Nout = 8;									% obj.Optic.Nout
  pos = pos + obj.pos;				% mirror position
  
  % optic parametes as vectors for each field component
  [vThr, vLhr, vRar, vLmd] = obj.getVecProperties(par.lambda, par.pol);

  % dl/dx (non-zero for reflected fields)
  dldx = zeros(Nout, Nin);
  caoi = cos(pi * obj.aoi / 180);
  dldx(1, 1) = -2 * caoi;
  dldx(2:4, 2) = 2 * caoi;
  dldx(5:8, 3:4) = dldx(1:4, 1:2);  % B-side

  % direction matrices
  mDirIn = diag([-caoi,caoi,-caoi,caoi]);
  mDirOut = diag([-caoi,caoi,caoi,caoi,-caoi,caoi,caoi,caoi]);
  
  % prepare the scattering matrices
  m = zeros(Nout, Nin);                 % single field, no phases
  mOpt = zeros(Nrf * Nout, Nrf * Nin);  % full scattering matrix

  % ==== Compute for each RF component
  for n = 1:Nrf
    % amplitude reflectivities, transmissivities and phases
    hr = -sqrt(1 - vThr(n) - vLhr(n));	% HR refl
    ht =  sqrt(vThr(n));               % HR trans
    ar = -sqrt(vRar(n));               % AR refl
    at =  sqrt(1 - vRar(n));           % AR trans
    bt =  sqrt(1 - vLmd(n));           % bulk trans
    
    % flip reflection signs for P-polarization
    if par.pol(n) == Optickle.polP
      hr = -hr;
      ar = -ar;
    end
      
    % transmission combinations
    hrbt = -hr * bt;
    arbt = -ar * bt;
    htbt =  ht * bt;
    atbt =  at * bt;
    
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

    % reflection phase due to mirror position
    rp = exp(1i * par.k(n) * pos * dldx);

    % enter this submatrix into mOpt
    nn = (1:Nout) + Nout * (n - 1);
    mm = (1:Nin) + Nin * (n - 1);
    mOpt(nn, mm) = m .* rp;
  end
end