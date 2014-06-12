% getFieldMatrix method
%   returns a mOpt, the field transfer matrix for this optic
%
% mOpt = getFieldMatrix(obj, par)

function mOpt = getFieldMatrix(obj, pos, par)

  % constants
  Nrf = par.Nrf;
  vFrf = par.vFrf;
  vKrf = opt.k;
  vpol = opt.pol;
  fMod = obj.fMod;
  aMod = obj.aMod;
  LIGHT_SPEED = Optickle.c;
  
  % loop over RF components
  mOpt = zeros(Nrf, Nrf);
  for n = 1:Nrf
    % reduce input RF component
    mOpt(n, n) = besselj(0, imag(aMod)) * (1 - real(aMod)^2 / 4);

    % loop over RF components again to look for RF frequency matches
    for m = 1:Nrf
      % only bother with same polarization fields
      if vpol(n) == vpol(m)
        % frequency differences (including wavelength differences)
        df = abs(vKrf(m) - vKrf(n)) * LIGHTSPEED / (2*pi);
        n_df = round(df / fMod);
        r_df = abs(df - n_df * fMod);
        if r_df < 1e-3 && n_df ~= 0
          mOpt(m, n) = besselj(n_df, imag(aMod)) * 1i^n_df;
          if n_df == 1 || n_df == -1
            mOpt(m, n) = mOpt(m, n) + real(aMod) / 2;
          end
        elseif r_df < 1 && n_df ~= 0
          warning(['Modulation frequency near-miss for RFmodulator %s ' ...
            'with RF components %d and %d.'], obj.Optic.name, n, m)
        end
      end
    end
  end