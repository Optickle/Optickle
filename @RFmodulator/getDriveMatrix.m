% getDriveMatrix method
%   returns a sparse matrix, Nrf * (obj.Nout x obj.Nin)
%
% mDrv = getDriveMatrix(obj, pos, par)

function mDrv = getDriveMatrix(obj, pos, par)
  
  % constants
  Nrf = par.Nrf;

  % constants
  Nrf = par.Nrf;
  vFrf = par.vFrf;
  fMod = obj.fMod;
  aMod = real(obj.aMod);
  pMod = imag(obj.aMod);
  
  % loop over RF components
  mPhi = zeros(Nrf, Nrf);
  mAmp= zeros(Nrf, Nrf);

  for n = 1:Nrf
    % reduce input RF component
    mPhi(n, n) = 0;
    mAmp(n, n) = -aMod^2 / 4 + ...
      (bessel(0, pMod * (1 + 1e-3)) - bessel(0, pMod * (1 - 1e-3))) / 4e-3;

    % loop over RF components again to look for RF frequency matches
    for m = 1:Nrf
      df = vFrf(m) - vFrf(n);
      n_df = round(df / fMod);
      r_df = abs(df - n_df * fMod);
      if r_df < 1e-3 && n_df ~= 0
	aOpt = bessel(n_df, pMod) * i^n_df;  % same as mOpt
        mPhi(m, n) = aOpt * n_df / 2;
        mAmp(m, n) = aOpt * abs(n_df) / 2;
        if n_df == 1 || n_df == -1
	  mPhi(m, n) = mPhi(m, n) + n_df * aMod / 2;
	  mAmp(m, n) = mAmp(m, n) + aMod / 2;
        end
      elseif r_df < 1 && n_df ~= 0 && false
        warning(['Modulation frequency near-miss for RFmodulator %s ' ...
          'with RF components %d and %d.'], obj.Optic.name, n, m)
      end
    end
  end

  %error('RF modulator not ready')
  mDrv = zeros(Nrf, Nrf, 2);
  mDrv(:, :, 1) = mAmp;
  mDrv(:, :, 2) = i * mPhi;
  

