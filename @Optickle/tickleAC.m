% backend function for tickle and tickle01
%
% [vDC, mPrb] = tickleAC(opt, pos)


function varargout = tickleAC(opt, f, nDrive, ...
  vLen, vPhiGouy, mPhiFrf, mPrb, mOptGen, mRadFrc, lResp, mQuant, shotPrb)

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
  jMsb = 1:Nfld;          % minus sideband
  jPsb = Nfld + jMsb;     % plus sideband
  jAsb = 1:Narf;          % all fields
  jDrv = (1:Ndrv) + Narf; % drives
  
  % combine probe and output matrix
  if isempty(opt.mProbeOut)
    mOut = mPrb;
  else
    mOut = opt.mProbeOut * mPrb;
  end
  Nout = size(mOut, 1);

  % output drive selection (HACK: change to output matrix)
  if ~isempty(nDrive)
    jDrv = jDrv(nDrive);
    NdrvOut = numel(nDrive);
  else
    NdrvOut = Ndrv;
  end
  
  % intialize result space
  eyeNdof   = speye(Ndof);
  mExc      = eyeNdof(:, jDrv);
  sigAC     = zeros(Nout, NdrvOut, Naf);
  mMech     = zeros(NdrvOut, NdrvOut, Naf);
  noiseAC   = zeros(Nout, Naf);
  noiseMech = zeros(NdrvOut, Naf);
  
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
    
    % ==== Put it together and solve
    mDof = [  mPhi * mOptGen
             mResp * mRadFrc ];
    
    tfAC = (eyeNdof - mDof) \ mExc;
    
    % extract optic to probe transfer functions
    sigAC(:, :, nAF) = 2 * mOut * tfAC(jAsb, :);
    mMech(:, :, nAF) = tfAC(jDrv, :);
    
    if isNoise
      %%%% With Quantum Noise
      mQinj = blkdiag(mPhi, mResp) * mQuant;
      mNoise = (eyeNdof - mDof) \ mQinj;
      noisePrb = mOut * mNoise(jAsb, :);
      noiseDrv = mNoise(jDrv, :);
      
      % incoherent sum of amplitude and phase noise
      noiseAC(:, nAF) = sqrt(sum(abs(noisePrb).^2, 2) + shotPrb);
      noiseMech(:, nAF) = sqrt(sum(abs(noiseDrv).^2, 2));
      
      % for debugging
%   fprintf('\n\n======== mNoise \n')
%   disp((full(mNoise)) * 1e10 / 4.3208)
%   fprintf('\n-- mPrb 1\n')
%   disp(full(mPrb(1, jMsb) * mNoise(jMsb, :)) * 1e10 / 4.3208)
%   disp(full(mPrb(1, jPsb) * mNoise(jPsb, :)) * 1e10 / 4.3208)
%   fprintf('\n-- mPrb 2\n')
%   disp(full(mPrb(2, jMsb) * mNoise(jMsb, :)) * 1e10 / 4.3208)
%   disp(full(mPrb(2, jPsb) * mNoise(jPsb, :)) * 1e10 / 4.3208)
  
      % HACK: noise probe
      %tmpPrb(nAF, :) = abs(noisePrb(nTmpProbe, :)).^2;
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
  varargout{1} = sigAC;
  varargout{2} = mMech;
  if isNoise
    varargout{3} = noiseAC;
    varargout{4} = noiseMech;
  end
end
