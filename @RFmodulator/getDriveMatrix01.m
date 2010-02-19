% getDriveMatrix method, TEM01 mode
%   returns a sparse matrix, Nrf * (obj.Nout x obj.Nin)
%
% HACK - for now this is just the same as for TEM00
%
% mDrv = getDriveMatrix01(obj, pos, par)

function mDrv = getDriveMatrix01(obj, pos, vBasis, par)
  
  % constants
  Nrf = par.Nrf;
  vFrf = par.vFrf;
  fMod = obj.fMod;
  aMod = real(obj.aMod);
  pMod = imag(obj.aMod);

  % loop over RF components
  mPhi = zeros(Nrf, Nrf);
  mAmp = zeros(Nrf, Nrf);

  for n = 1:Nrf
    % carrier modulation due to oscillator phase and amplitude modulation
    mPhi(n, n) = 0;
    mAmp(n, n) = dbessel(0, pMod) / 2;
    
    % loop over RF components again to look for RF frequency matches
    %   most of this is copied from getFieldMatrix
    for m = 1:Nrf
      df = vFrf(m) - vFrf(n);
      n_df = round(df / fMod);
      r_df = abs(df - n_df * fMod);
      if r_df < 1e-3 && n_df ~= 0
        % phase and amplitude audio SBs on RF phase modulation
        mPhi(m, n) = bessel(n_df, pMod) * 1i^n_df * n_df / 2;
        mAmp(m, n) = dbessel(n_df, pMod) * 1i^n_df / 2;

        % phase and amplitude audio SBs on RF amplitude modulation
        if n_df == 1 || n_df == -1
          mPhi(m, n) = mPhi(m, n) + n_df * aMod / 4;
          mAmp(m, n) = mAmp(m, n) + aMod / 4;
        end
      end
    end
  end

  % build drive matrix
  mDrv = zeros(Nrf, Nrf, 2);
  mDrv(:, :, 1) = mAmp;
  mDrv(:, :, 2) = 1i * mPhi;

end
