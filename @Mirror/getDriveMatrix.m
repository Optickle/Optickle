% getDriveMatrix method
%   returns the drive coupling matrix, Nrf * (obj.Nout x obj.Nin)
%
% mCpl = getDriveMatrix(obj, pos, par)

function mCpl = getDriveMatrix(obj, pos, par, mOpt, dldx)
  
  % check for optional arguments
  if nargin < 4
    [mOpt, ~, ~, dldx] = getFieldMatrix(obj, pos, par);
  end
  
  % constants
  Nrf = par.Nrf;
  Nin = 2;					% obj.Nin
  Nout = 4;					% obj.Nout
  
  if par.tfType ~= Optickle.tfPos  % not pos case
      
      % output basis, where the basis is undefined, put z = 0, z0 = 1
      vBout = apply(getBasisMatrix(obj), par.vBin);
      vBout(~isfinite(vBout)) = 1i;
      
      % mirror TEM01/10 mode injections at the waist are
      %   theta / theta0 = theta * sqrt(k * z0 / 2)
      % adding a non-zero distance from the waist, we must scale by
      %   w(z) / w0 = sqrt(1 + (z/z0)^2)
      % The sqrt(k / 2) part is done separately for each RF component
      % the sqrt(z0 * (1 + (z/z0)^2)) is done for each link using the
      % the injection matrix, mInj, computed below.
      %
      
      %   the y-basis, vBout(:,2), is of interest for the vertical 01
      %   mode
      %   the x-basis, vBout(:,1), is of interest for the horizontal 10 mode
      z    =  real(vBout(:,par.nBasis));
      z0   = -imag(vBout(:,par.nBasis));
      mInj = diag(sqrt(z0 .* (1 + (z ./ z0).^2))); %sqrt(z0*w(z)/w0)
  end
  
  
  
  
  %drive matrix
  mCpl = zeros(Nrf * Nout, Nrf * Nin);
  for n = 1:Nrf
    % select reflection phase drive coefficient depending on dof

    if par.tfType == Optickle.tfPos
        drp = 1i * par.k(n) * dldx / 2;
        
    elseif par.tfType == Optickle.tfPit %pitch/01 case
        drp = 1i * sqrt(par.k(n) / 2) * (mInj * dldx / 2);
                                               
    elseif par.tfType == Optickle.tfYaw %yaw/10 case
        drp = 1i * sqrt(par.k(n) / 2) * (mInj * sign(dldx / 2)); %sign removes
                                                                 %angle of
                                                                 %incidence dependence
    end
    
    % enter this submatrix into mCpl
    nn = (1:Nout) + Nout * (n - 1);
    mm = (1:Nin) + Nin * (n - 1);
    mCpl(nn, mm) = mOpt(nn, mm) .* drp;
  end
end
