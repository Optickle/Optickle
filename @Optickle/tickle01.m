% Compute AC transfer functions for a TEM01 mode (pitch).
%
% [sigAC, mMech] = tickle01(opt, pos, f)
% opt - Optickle model
% pos - optic positions (Ndrive x 1, or empty)
% f - audio frequency vector (Naf x 1)
% nDrive - drive indices to consider (Nx1, default is all)
%
% sigAC - transfer matrix (Nprobe x Ndrive x Naf),
%   where Ndrive is the total number of optic drive
%   inputs (e.g., 1 for a mirror, 2 for a RFmodulator).
%   Thus, sigAC is arranged such that sigAC(n, m, :)
%   is the TF from the drive m to probe n.
%
% mMech - modified drive transfer functions (Ndrv x Ndrv x Naf)
%
% NOTE: like tickle, sigAC is the product of the DC field amplitude
% with the AC sideband amplitude.  This IGNORES the overlap integral
% between the TEM00 and TEM01 modes on a given detector geometry.
% For a half plane detector, the correction factor is sqrt(pi/2).
%   === Thanks to Yuta Michimora!!! ===
%
% To convert DC signals to beam-spot motion, scale by w/(2 * Pdc),
% where w is the beam size at the probe.
%   === Thanks to Yuta Michimora!!! ===
%
% Example:
% f = logspace(0, 3, 300);
% opt = optFP;
% [sigAC, mMech] = tickle01(opt, [], f);

% 1/20/2011 N. Smith added nDrive as optional argument, allows calculation
% to be performed faster if only a subset of the drive points will be used.


function varargout = tickle01(opt, pos, f, nDrive)

  % === Argument Handling
  if nargin < 3
    error('No frequency vector given.  Use tickle for DC results.')
  end
  if nargin < 4
    nDrive = [];
  end

  % === Field Info
  vFrf = opt.vFrf;
  
  % ==== Sizes of Things
  Ndrv = opt.Ndrive;		% number of drives (internal DOFs)
  Nlnk = opt.Nlink;		% number of links
  Nprb = opt.Nprobe;		% number of probes
  Nrf  = length(vFrf);		% number of RF components
  Naf  = length(f);		% number of audio frequencies
  Nfld = Nlnk * Nrf;		% number of RF fields
  Narf = 2 * Nfld;		% number of audio fields
  Ndof = Narf + Ndrv;		% number of degrees-of-freedom
  
  % check the memory requirements
  memReq = (20 * Nprb *  Ndrv *  Naf) / 1e6;
  if memReq > 200
    qstr = sprintf('This will require about %.0f Mb of memory.', memReq);
    rstr = questdlg([qstr ' Continue?'], 'ComputeFields', ...
      'Yes', 'No', 'No');
    if strcmp(rstr, 'No')
      error('Too much memory required.  Exiting.');
    end
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % ==== DC Fields and Signals
  % duplicated from tickle
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  [vLen, prbList, mapList, mPhiFrf, vDC, mPrb, mPrbQ] = ...
    tickleDC(opt, pos);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % ==== Audio Frequency Loop
  % mostly duplicated from tickle
  %  phase includes Gouy phase
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % get basis vector
  vBasis = getAllFieldBases(opt);
  
  % Gouy phases... take y-basis for TEM01 mode (pitch)
  lnks = opt.link;
  vDist = [lnks.len]';
  vPhiGouy = getGouyPhase(vDist, vBasis(:, 2));

  % expand the probe matrix to both audio SBs
  mPrb = sparse([mPrb, conj(mPrb)]);
  
  % get optic matricies for AC part
  [mOptGen, mRadFrc, lResp, mQuant] = ...
    convertOptics01(opt, mapList, pos, f, vDC);
  
  % noise stuff
  if isNoise
    [Nnoise, mQuant, shotPrb] = tickleShot(opt, prbList, vDC, mQuant);
  else
    Nnoise = 0;
  end
    
  % useful indices
  jAsb = 1:Narf;
  jDrv = (1:Ndrv) + Narf;
  if ~isempty(nDrive)
    jDrv = jDrv(nDrive);
    NdrvOut = numel(nDrive);
  else
    NdrvOut = Ndrv;
  end
  
  % main inversion tools
  mOOz = sparse(NdrvOut, NdrvOut);
  eyeNdof = speye(Ndof);

  % intialize result space
  mExc = eyeNdof(:, jDrv);
  sigAC = zeros(Nprb, NdrvOut, Naf);
  mMech = zeros(NdrvOut, NdrvOut, Naf);
  noiseAC = zeros(Nprb, Naf);
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
    %   Gouy phase has minus sign
    mPhim = getPhaseMatrix(vLen, vFrf - fAudio, -vPhiGouy, mPhiFrf);
    mPhip = getPhaseMatrix(vLen, vFrf + fAudio, -vPhiGouy, mPhiFrf);
    mPhi = blkdiag(mPhip,conj(mPhim));

    % mechanical response matrix
    mResp = diag(lResp(nAF,:));
    
    % ==== Put it together and solve
    mDof = [  mPhi * mOptGen
             mResp * mRadFrc ];
    
    tfAC = (eyeNdof - mDof) \ mExc;

    % field TF matrix wanted?
    if isOut_tfAC
      tfACout(:, :, nAF) = tfAC(jAsbAC, :);
    end
    
    % extract optic to probe transfer functions
    sigAC(:, :, nAF) = 2 * mPrb * tfAC(jAsb, :);
    mMech(:, :, nAF) = tfAC(jDrv, :);
    
    if isNoise
      %%%% With Quantum Noise
      mQinj = [mPhi * mQuant;  mQOz];
      mNoise = (eyeNdof - mDof) \ mQinj;
      noisePrb = mPrb * mNoise(jAsb, :);
      noiseDrv = mNoise(jDrv, :);
      
      % incoherent sum of amplitude and phase noise
      noiseAC(:, nAF) = sqrt(sum(abs(noisePrb).^2, 2) + shotPrb);
      noiseMech(:, nAF) = sqrt(sum(abs(noiseDrv).^2, 2));
      
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

  % Build the rest of the outputs
  varargout{1} = sigAC;
  varargout{2} = mMech;
  if isNoise
      varargout{3} = noiseAC;
      varargout{4} = noiseMech;
  end
end