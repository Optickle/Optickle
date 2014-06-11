% Compute DC fields, and DC signals, and AC transfer functions
%
% [fDC, sigDC, sigAC, mMech, noiseAC, noiseMech] = tickle(opt, pos, f, nDrive)
% opt       - Optickle model
% pos       - optic positions (Ndrive x 1, or empty)
% f         - audio frequency vector (Naf x 1)
% nDrive    - drive indices to consider (Nx1, default is all)
%
% fDC       - DC fields at this position (Nlink x Nrf)
%             where Nlink is the number of links, and Nrf
%             is the number of RF frequency components.
% sigDC     - DC signals for each probe (Nprobe x 1)
%             where Nprobe is the number of probes.
% sigAC     - transfer matrix (Nprobe x Ndrive x Naf),
%             where Ndrive is the total number of optic drive
%             inputs (e.g., 1 for a mirror, 2 for a RFmodulator).
%             Thus, sigAC is arranged such that sigAC(n, m, :)
%             is the TF from the drive m to probe n.
% mMech     - modified drive transfer functions (Ndrv x Ndrv x Naf)
% noiseAC   - quantum noise at each probe (Nprb x Naf)
% noiseMech - quantum noise at each drive (Ndrv x Naf)
%
% UNITS:
% Assuming the input laser power is in Watts, and laser wavelength is in
% meters, the outputs are generically 
% fDC   - [sqrt(W)]
% sigDC - [W]
% sigAC - [W/m]
% assuming the drive is a mirror. If the drive is a modulator, then sigAC
% is [W/AM] or [W/rad] for an amplitude or phase modulation, respectively.
%
% EXAMPLE:
% f = logspace(0, 3, 300);
% opt = optFP;
% [fDC, sigDC, sigAC, mMech] = tickle(opt, [], f);
%
% 
% $Id: tickle.m,v 1.14 2011/07/26 23:09:57 tfricke Exp $


function varargout = tickle(opt, pos, f, nDrive, nField_tfAC)

  % === Argument Handling
  if nargin < 2
    pos = [];
  end
  if nargin < 3
    f = [];
  end
  if nargin < 4
    nDrive = [];
  end
  
  % third argument is actually control struct (see convertSimulink)
  isCon = isstruct(f);
  if isCon
    sCon = f;
    f = sCon.f;
  end
  
  % forth and fith argument given, return tfAC as last return argument
  isOut_tfAC = nargin >= 5;
  
  % === Field Info
  [vFrf, vSrc] = getSourceInfo(opt);
  LIGHT_SPEED = Optickle.c;
  
  % ==== Sizes of Things
  Ndrv = opt.Ndrive;	% number of drives (internal DOFs)
  Nlnk = opt.Nlink;		% number of links
  Nprb = opt.Nprobe;	% number of probes
  Nrf  = length(vFrf);	% number of RF components
  Naf  = length(f);		% number of audio frequencies
  Nfld = Nlnk * Nrf;	% number of RF fields
  Narf = 2 * Nfld;		% number of audio fields
  Ndof = Narf + Ndrv;	% number of degrees-of-freedom
  
  % decide which calculation is necessary
  isAC = ~isempty(f) && nargout > 2;
  isNoise = isAC && (nargout > 4 || (isCon && nargout > 3));

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
  % Convert to Matrix Form
  %   opt, the Optickle model, is not used after this section
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % link and probe conversion
  [vLen, prbList, mapList, mPhiFrf] = convertLinks(opt);

  % optic conversion
  mOpt = convertOpticsDC(opt, mapList, pos);
  
  % noise stuff
  Nnoise = size(mQuant, 2);
  pQuant  = opt.h * opt.k * opt.c / (4 * pi);
  aQuant = sqrt(pQuant) / 2;
  aQuantTemp = repmat(aQuant',opt.Nlink,1); % aQuant is
                                             % Nrfx1. mQuant is
                                             % Nlink*Nrf x number
                                             % of loss points*2

  aQuantMatrix = diag(aQuantTemp(:));
  mQuant = aQuantMatrix * mQuant;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % ==== DC Fields and Signals
  % Here, the DC fields for each RF component are evaluated
  % at each field evaluation point (FEP, at each link end).
  %
  % Using the DC fields in vDC, we can now finish the probe
  % matrix Mprb, and with that we can compute the DC signals.
  %
  % For easier use outside this function, the DC fields are
  % reshaped and returned in a matrix fDC, which is Nlnk x Nrf.
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % compute DC fields
  eyeNfld = speye(Nfld);			% a sparse identity matrix
  mPhi = getPhaseMatrix(vLen, vFrf, [], mPhiFrf);		% propagation phase matrix
  vDC = (eyeNfld - (mPhi * mOpt)) \ (mPhi * vSrc);

  % compile system wide probe matrix and probe shot noise vector
  mPrb = sparse(Nprb, Narf);
  mPrbQ = sparse(Nprb, Nfld);
  shotPrb = zeros(Nprb, 1);
  for k = 1:Nprb
    mIn_k = prbList(k).mIn;
    mPrb_k = prbList(k).mPrb;
    
    vDCin = mIn_k * vDC;
    mPrb(k, 1:Nfld) = (mPrb_k * conj(vDCin)).' * mIn_k;
    mPrb(k, (1:Nfld) + Nfld) = (mPrb_k.' * vDCin).' * mIn_k;
    
    % quad phase signals, for oscillator phase noise
    mPrbQ_k = prbList(k).mPrbQ;
    mPrbQ(k, :) = (mPrbQ_k * conj(vDCin)).' * mIn_k;

    % shot noise
    if isNoise

        % This section attempts to account for the shot noise due to
        % fields which are not recorded by a detector. E.g. a 10
        % MHz detector will not see signal due to 37 MHz sidebands
        % but it should see their shot noise  
        
        % Define a new vDCin which includes the appropriate pQuant
        % for each dc component
        pQuantTemp = repmat(pQuant',opt.Nlink,1);
        pQuantMatrix = diag(pQuantTemp(:));
        vDCinShot = mIn_k * pQuantMatrix * vDC;
        
        shotPrb(k) = (2 - sum(abs(mPrb_k), 1)) * abs(vDCinShot).^2;

    end
  end
  
  %%%%% compute DC outputs
  % sigDC is already real, but use "real" to remove numerical junk
  sigDC = real(mPrb(:, 1:Nfld) * vDC) / 2;
  sigQ = real(mPrbQ * vDC) / 2;
  fDC = reshape(vDC, Nlnk, Nrf);		% DC fields for output

  % Build DC outputs
  varargout{1} = fDC;
  varargout{2} = sigDC;
  
  % if AC is not needed, just end here
  if ~isAC
    return
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % ==== Audio Frequency Loop
  % This is the section in which the tranfer functions
  % from optic drives to signals and optic positions are
  % computed (sigAC and mMech).
  %   sigAC: drive to signal TFs      Nprb x Ndrv x Naf
  %   mMech: drive to position TFs    Ndrv x Ndrv x Naf
  %
  % These are arranged such that sigAC(n, m, :) is the TF from
  % drive m to probe n, at all frequencies.
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % get optic matricies for AC part
  [mOptGen, mRadFrc, mResp, mQuant] = convertOpticsAC(opt, mapList, pos, f, vDC);
  
  % prepare generation matrix (part of optic-field matrix)
  mGen = sparse(Nfld, Ndrv);
  for n = 1:Ndrv
    mGen(:, n) = drvList(n).m * vDC;
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
  mDC = sparse(1:Nfld, 1:Nfld, vDC, Nfld, Nfld);

  mFFz = sparse(Nfld, Nfld);
  mOOz = sparse(Ndrv, Ndrv);
  mQOz = sparse(Ndrv, Nnoise);
  eyeNdof = speye(Ndof);

  % intialize result space
  if ~isCon
    % full results: all probes, all drives
    mExc = eyeNdof(:, jDrv);
    sigAC = zeros(Nprb, NdrvOut, Naf);
    mMech = zeros(NdrvOut, NdrvOut, Naf);
    noiseAC = zeros(Nprb, Naf);
    noiseMech = zeros(NdrvOut, Naf);
  else
    % reduced results for control struct
    mExc = eyeNdof(:, jDrv) * sCon.mDrvOut;

    sOpt.mInOut = zeros(sCon.Nout, sCon.Nin, Naf);
    sOpt.mPlant = zeros(sCon.Nin, sCon.Nout, Naf);
    sOpt.mOpenLoop = zeros(sCon.Nout, sCon.Nout, Naf);
    sOpt.mCloseLoop = zeros(sCon.Nout, sCon.Nout, Naf);
    
    eyeNout = eye(sCon.Nout);
    mPrbPrb = sCon.mPrbIn * sparse(diag(sigQ)) * sCon.mPrbOut;

    if isNoise
      noiseOut = zeros(sCon.Nout, Naf);
      shotPrbAmp = sqrt(shotPrb);
    end
  end
  
  % is tfAC wanted?
  if isOut_tfAC
    tfACout = zeros(2 * numel(nField_tfAC), NdrvOut, Naf);
    jAsbAC = [jAsb(nField_tfAC), jAsb(Nfld + nField_tfAC)];
  end
    
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
    mPhim = getPhaseMatrix(vLen, vFrf - fAudio,[],mPhiFrf);
    mPhip = getPhaseMatrix(vLen, vFrf + fAudio,[],mPhiFrf);

    % field to optic position transfer
    mFOm = rctList(nAF).m * conj(mDC) / LIGHT_SPEED;
    mFOp = rctList(nAF).m * mDC / LIGHT_SPEED;

    % field to field transfer
    mFFm = mPhim * mOpt;
    mFFp = conj(mPhip * mOpt);

    % optic to field transfer
    mOFm = mPhim * mGen;
    mOFp = conj(mPhip * mGen);
    
    % ==== Put it together and solve
    mDof = [mFFm, mFFz, mOFm; mFFz, mFFp, mOFp; mFOm, mFOp, mOOz];
    tfAC = (eyeNdof - mDof) \ mExc;

    % field TF matrix wanted?
    if isOut_tfAC
      tfACout(:, :, nAF) = tfAC(jAsbAC, :);
    end
    
    % extract optic to probe transfer functions
    if ~isCon
      % no control struct, return TFs to all probes and drives
      sigAC(:, :, nAF) = mPrb * tfAC(jAsb, :);
      mMech(:, :, nAF) = tfAC(jDrv, :);
    else
      % reduce probes and drives to those required by control struct
      mPlant = sCon.mPrbIn * mPrb * tfAC(jAsb, :) + ...
        sCon.mDrvIn * tfAC(jDrv, :) + mPrbPrb;
      
      % compute closed loop response of outputs
      mCon = sCon.mCon(:, :, nAF);
      mOL = mCon * mPlant;
      mCL = inv(eyeNout - mOL);
      mInOut = mCL * mCon;
      
      % store into the sOpt struct
      sOpt.mInOut(:, :, nAF) = mInOut;
      sOpt.mPlant(:, :, nAF) = mPlant;
      sOpt.mOpenLoop(:, :, nAF) = mOL;
      sOpt.mCloseLoop(:, :, nAF) = mCL;
    end
    
    if isNoise
      %%%% With Quantum Noise
      mQinj = [mPhim * mQuant; conj(mPhip * mQuant); mQOz];
      mNoise = (eyeNdof - mDof) \ mQinj;
      noisePrb = mPrb * mNoise(jAsb, :);
      noiseDrv = mNoise(jDrv, :);
      
      % incoherent sum of amplitude and phase noise
      if ~isCon
        noiseAC(:, nAF) = sqrt(sum(abs(noisePrb).^2, 2) + shotPrb);
        noiseMech(:, nAF) = sqrt(sum(abs(noiseDrv).^2, 2));
      else
        % transfer noise to outputs
        noiseAmp = mInOut * (sCon.mPrbIn * noisePrb + ...
          sCon.mDrvIn * noiseDrv);
        noisePrbAmp = mInOut * sCon.mPrbIn * shotPrbAmp;
        noiseOut(:, nAF) = sqrt(sum(abs(noiseAmp).^2, 2) + ...
          abs(noisePrbAmp).^2);
      end
      
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
  if ~isCon
    varargout{3} = sigAC;
    varargout{4} = mMech;
    if isNoise
      varargout{5} = noiseAC;
      varargout{6} = noiseMech;
    end
  else
    varargout{3} = sOpt;
    if isNoise
      varargout{4} = noiseOut;
    end
  end

  if isOut_tfAC && nargout > 0
    varargout{nargout} = tfACout;
  end
