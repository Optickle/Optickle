% Compute DC fields, and DC signals, and AC transfer functions
%
% [fDC, sigDC, sigAC, mMech, noiseAC, noiseMech] = tickle(opt, pos, f)
% opt - Optickle model
% pos - optic positions (Ndrive x 1, or empty)
% f - audio frequency vector (Naf x 1)
%
% fDC - DC fields at this position (Nlink x Nrf)
%   where Nlink is the number of links, and Nrf
%   is the number of RF frequency components.
% sigDC - DC signals for each probe (Nprobe x 1)
%  where Nprobe is the number of probes.
% sigAC - transfer matrix (Nprobe x Ndrive x Naf),
%   where Ndrive is the total number of optic drive
%   inputs (e.g., 1 for a mirror, 2 for a modulator).
%   Thus, sigAC is arranged such that sigAC(n, m, :)
%   is the TF from the drive m to probe n.
% mMech - modified drive transfer functions (Ndrv x Ndrv x Naf)
%
% Example:
% f = logspace(0, 3, 300);
% opt = optFP;
% [fDC, sigDC, sigAC, mMech] = tickle(opt, [], f);

function [fDC, sigDC, sigAC, mMech, noiseAC, noiseMech, shotPrb] = ...
  tickle(opt, pos, f)

  % === Argument Handling
  if nargin < 2
    pos = [];
  end
  if nargin < 3
    f = [];
  end

  % === Field Info
  [vFrf, vSrc] = getSourceInfo(opt);
  LIGHT_SPEED = opt.c;
  
  % ==== Sizes of Things
  Ndrv = opt.Ndrive;		% number of drives (internal DOFs)
  Nlnk = opt.Nlink;		% number of links
  Nprb = opt.Nprobe;		% number of probes
  Nrf  = length(vFrf);		% number of RF components
  Naf  = length(f);		% number of audio frequencies
  Nfld = Nlnk * Nrf;		% number of RF fields
  Narf = 2 * Nfld;		% number of audio fields
  Ndof = Narf + Ndrv;		% number of degrees-of-freedom
  
  % decide which calculation is necessary
  isAC = ~isempty(f) && nargout > 2;
  isNoise = isAC && nargout > 4;
  
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
  [vLen, prbList, mapList] = convertLinks(opt);

  % optic conversion
  [mOpt, rctList, drvList, mQuant] = convertOptics(opt, mapList, pos, f);
  
  % noise stuff
  Nnoise = size(mQuant, 2);
  pQuant = opt.h * opt.c / (2 * opt.lambda);
  aQuant = sqrt(pQuant) / 2;
  mQuant = mQuant * aQuant;
  
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
  mPhi = getPhaseMatrix(vLen, vFrf);		% propagation phase matrix
  vDC = (eyeNfld - (mPhi * mOpt)) \ (mPhi * vSrc);

  % compile system wide probe matrix and probe shot noise vector
  mPrb = sparse(Nprb, Narf);
  shotPrb = zeros(Nprb, 1);
  for k = 1:Nprb
    mIn_k = prbList(k).mIn;
    mPrb_k = prbList(k).mPrb;
    
    vDCin = mIn_k * vDC;
    mPrb(k, 1:Nfld) = (mPrb_k * conj(vDCin)).' * mIn_k;
    mPrb(k, (1:Nfld) + Nfld) = (mPrb_k.' * vDCin).' * mIn_k;
    
    % shot noise
    if isNoise
      shotPrb(k) = pQuant * (2 - sum(abs(mPrb_k), 1)) * abs(vDCin).^2;
    end
  end

  %%%%% compute DC outputs
  % sigDC is already real, but use "real" to remove numerical junk
  sigDC = real(mPrb(:, 1:Nfld) * vDC) / 2;
  fDC = reshape(vDC, Nlnk, Nrf);		% DC fields for output

  % if AC is not needed, just end here
  if ~isAC
    sigAC = zeros(Nprb, Ndrv, 0);
    mMech = zeros(Ndrv, Ndrv, 0);
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

  % prepare generation matrix (part of optic-field matrix)
  mGen = sparse(Nfld, Ndrv);
  for n = 1:Ndrv
    mGen(:, n) = drvList(n).m * vDC;
  end
  
  % useful indices
  jAsb = 1:Narf;
  jDrv = (1:Ndrv) + Narf;
  
  % main inversion tools
  mDC = sparse(1:Nfld, 1:Nfld, vDC, Nfld, Nfld);

  mFFz = sparse(Nfld, Nfld);
  mOOz = sparse(Ndrv, Ndrv);
  mQOz = sparse(Ndrv, Nnoise);
  eyeNdof = speye(Ndof);
  mExc = eyeNdof(:, jDrv);

  % intialize result space
  sigAC = zeros(Nprb, Ndrv, Naf);
  mMech = zeros(Ndrv, Ndrv, Naf);

  noiseAC = zeros(Nprb, Naf);
  noiseMech = zeros(Ndrv, Naf);
  
  % since this can take a while, let's time it
  tic;
  hWaitBar = [];
  tLast = 0;
  
  % audio frequency loop
  for nAF = 1:Naf
    fAudio = f(nAF);

    % propagation phase matrices
    mPhim = getPhaseMatrix(vLen, vFrf - fAudio);
    mPhip = getPhaseMatrix(vLen, vFrf + fAudio);

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

    % extract optic to probe transfer functions
    sigAC(:, :, nAF) = mPrb * tfAC(jAsb, :);
    mMech(:, :, nAF) = tfAC(jDrv, :);

    if isNoise
      %%%% With Quantum Noise
      mQinj = [mPhim * mQuant; conj(mPhip * mQuant); mQOz];
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
    if tNow > 2 && tRem > 2 && tNow - tLast > 0.5
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
