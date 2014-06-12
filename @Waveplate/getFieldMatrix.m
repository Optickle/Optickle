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

  lfw = obj.lfw;   % list of fraction of wave of the waveplate for each wavelength (e.g. 0.25 for QWP, 0.5 for HWP)
  vfw = Optickle.mapByLambda(lfw,opt.lambda);
  theta = obj.theta / 180 * pi;   % rotation angle of the waveplate
  mRot = [cos(theta),sin(theta);-sin(theta),cos(theta)]; 
  
  % loop over RF components
  mOpt = zeros(Nrf, Nrf);
  for n = 1:Nrf
    for m = 1:Nrf
      % wavenumber differences
      dk = abs(vKrf(m) - vKrf(n));
      if dk < 1e-3
        % Jones matrix
        mJones = inv(mRot) * [1,0;0,exp(-i*2*pi*vfw(n))] * mRot;
        for jj = 1:2
          for kk = 1:2
            if [vpol(n)+1,vpol(m)+1] == [jj,kk]
              mOpt(n,m) = mJones(jj,kk)
            end
          end
        end
      end
    end
  end