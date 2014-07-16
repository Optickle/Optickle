% backend function for tickle2
%
% [mOpt, mMech, noiseOpt, noiseMech] = tickleAC(opt, f, vLen, vPhiGouy, ...
%   mPhiFrf, mPrb, mOptGen, mRadFrc, lResp, mQuant, shotPrb)


function varargout = tickleAC(opt, f, vLen, vPhiGouy, ...
  mPhiFrf, mPrb, mOptGen, mRadFrc, lResp, mQuant, shotPrb)

  % === Field Info
  vFrf = opt.vFrf;
  
  % ==== Sizes of Things
  Ndrv = opt.Ndrive;   % number of drives (internal DOFs)
  Nlnk = opt.Nlink;    % number of links
  Nrf  = length(vFrf); % number of RF components
  Naf  = length(f);    % number of audio frequencies
  Nfld = Nlnk * Nrf;   % number of RF fields
  Narf = 2 * Nfld;     % number of audio fields
  Ndof = Narf + Ndrv;  % number of degrees - of - freedom
  
  isNoise = ~isempty(mQuant);
  
  % ==== Useful Indices
  jAsb = 1:Narf;          % all fields
  jDrv = (1:Ndrv) + Narf; % drives
  
  % combine probe and output matrix
  if isempty(opt.mProbeOut)
    mOut = mPrb;
  elseif size(opt.mProbeOut, 2) == size(mPrb, 1)
    mOut = opt.mProbeOut * mPrb;
  else
    error('opt.mProbeOut must have Nprobe columns')
  end
  Nout = size(mOut, 1);

  % make input to drive matrix
  if isempty(opt.mInDrive)
    mInDrv = eye(Ndrv);
  else
    mInDrv = opt.mInDrive;
  end
  mDrvIn = pinv(mInDrv);
  Nin = size(mInDrv, 2);

  % intialize result space
  eyeNdof   = speye(Ndof);
  %mExc      = eyeNdof(:, jDrv) * mInDrv;
  %sigAC     = zeros(Nout, Nin, Naf);
  eyeNarf   = speye(Narf);
  mOpt      = zeros(Nout, Nin, Naf);
  mMech     = zeros(Nin, Nin, Naf);
  noiseOpt  = zeros(Nout, Naf);
  noiseMech = zeros(Nin, Naf);
  
  % since this can take a while, let's time it
  tic;
  hWaitBar = [];
  tLast = 0;
  
  % prevent scale warnings
  sWarn = warning('off', 'MATLAB:nearlySingularMatrix');

  % audio frequency loop
  for nAF = 1:Naf
    fAudio = f(nAF);

    % propagation phase matrices
    mPhim = Optickle.getPhaseMatrix(vLen, vFrf - fAudio, -vPhiGouy, mPhiFrf);
    mPhip = Optickle.getPhaseMatrix(vLen, vFrf + fAudio, -vPhiGouy, mPhiFrf);
    mPhi = blkdiag(mPhim, conj(mPhip));
    
    % mechanical response matrix
    mResp = diag(lResp(nAF,:));
    
    %%%%%%%%%%%%% Reference Code (matches Optickle 1)
    % % ==== Put it together and solve
    % mDof = [  mPhi * mOptGen
    %          mResp * mRadFrc ];
    %
    % tfAC = (eyeNdof - mDof) \ mExc;

    % % extract optic to probe transfer functions
    % sigAC(:, :, nAF) = 2 * mOut * tfAC(jAsb, :);
    % mMech(:, :, nAF) = mDrvIn * tfAC(jDrv, :);
    
    %%%%%%%%%%%%% Piecewise Inversion
    % see Optickle2 documentation, secion 5.3 AC Matrix Inversion
    %   sigAC == mOpt * mMech
    
    mPhiOptGen = mPhi * mOptGen;
    mFF = mPhiOptGen(:, jAsb);    % field-field
    mOF = mPhiOptGen(:, jDrv);    % optic-field
    
    mRespRadFrc = mResp * mRadFrc;
    mFO = mRespRadFrc(:, jAsb);   % field-optic
    mOO = mRespRadFrc(:, jDrv);   % optic-optic
    
    tfOptAC = (eyeNarf - mFF) \ (mOF * mInDrv); % inputs to ASB amplitudes
    mOpt(:, :, nAF) = -2 * mOut * tfOptAC;
    mMech(:, :, nAF) = (mInDrv - mOO * mInDrv - mFO * tfOptAC) \ mInDrv;
    
    %%% Quantum noise
    if isNoise
      % setup
      mDof = [mPhiOptGen; mRespRadFrc];
      mQinj = blkdiag(mPhi, mResp) * mQuant;
      mNoise = (eyeNdof - mDof) \ mQinj;
      noisePrb = mOut * mNoise(jAsb, :);
      noiseDrv = mDrvIn * mNoise(jDrv, :);
      
      % incoherent sum of amplitude and phase noise
      noiseOpt(:, nAF) = sqrt(sum(abs(noisePrb).^2, 2) + shotPrb);
      noiseMech(:, nAF) = sqrt(sum(abs(noiseDrv).^2, 2));
    end
    
    % ==== Timing and User Interaction
    % NO MODELING HERE (just let the user know how long this will take)
    tNow = toc;
    frac = nAF / Naf;
    tRem = tNow * (1 / frac - 1);
    if tNow > 2 && tRem > 2 && tNow - tLast > 0.5 && opt.debug > 0
      % wait bar string
      str = sprintf('%.1f s used, %.1f s left', tNow, tRem);

      % check and update waitbar
      if isempty(hWaitBar)
        % create wait bar
        try
          strWB = [str ' (close this window to stop)'];
          hWaitBar = waitbar(frac, strWB, 'Name', 'Optickle: Computing...');
          tLast = tNow;
        catch
          % can't make wait bar... use text
          if tNow - tLast > 5
            disp(str)
            tLast = tNow;
          end
        end
      else
        try
          strWB = [str ' (close this window to stop)'];
          findobj(hWaitBar);			% error if wait bar closed
          waitbar(frac, hWaitBar, strWB);	% update wait string
          tLast = tNow;
        catch
          error('Wait bar closed by user.  Exiting.')
        end
      end
    end
  end
    
  % reset scale warning state
  warning(sWarn.state, sWarn.identifier);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % ==== Clean Up
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % close wait bar
  if ~isempty(hWaitBar)
    waitbar(1.0, hWaitBar, 'Done computing fields.  Returning...')
    close(hWaitBar)
  end

  % make sure that the wait bar is closed
  drawnow

  % Build the outputs
  varargout{1} = mOpt;
  varargout{2} = mMech;
  if isNoise
    varargout{3} = noiseOpt;
    varargout{4} = noiseMech;
  end
end
