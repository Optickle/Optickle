% Compute DC fields, and DC signals, and AC transfer functions
%   PARALLEL VERSION - runs on the matlabpool
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
%   inputs (e.g., 1 for a mirror, 2 for a RFmodulator).
%   Thus, sigAC is arranged such that sigAC(n, m, :)
%   is the TF from the drive m to probe n.
% mMech - modified drive transfer functions (Ndrv x Ndrv x Naf)
% noiseAC - quantum noise at each probe (Nprb x Naf)
% noiseMech - quantum noise at each drive (Ndrv x Naf)
%
% Example:
% f = logspace(0, 3, 300);
% opt = optFP;
% [fDC, sigDC, sigAC, mMech] = tickle(opt, [], f);


% %%%%%%%%%%%%%%%%%%%% With control struct
% [fDC, sigDC, sOpt, noiseOut] = tickle(opt, pos, sCon)
%
% An alternate means of using tickle is to pass a control struct
% as the third argument.  This control struct describes a controller
% which takes the outputs of the Optickle model (probe signals) and 
% precesses them to produce inputs to the model (drive signals).  See
% convertSimulink for more details.
%
% The control struct must contain the following fields:
%  f - frequency vector (Naf x 1)
%  Nin - control system inputs
%  Nout - control system outputs
%  mCon - control matrix for each f value (Nin x Nout x Naf)
%  mPrbIn - probe output to control system input map (Nin x Nprobe)
%  mDrvIn - drive output to control system input map (Nin x Ndrive)
%  mPrbOut - control system output to probe input map (Nprobe x  Nout)
%  mDrvOut - control system output to drive input map (Ndrive x  Nout)
%
% The results are the usual fDC and sigDC, along with an Optickle
% system struct which contains the following fields:
%  mPlant - transfer from control outputs to control inputs
%           this is taken from sigAC and mMech
%  mOpenLoop - open loop tranfer at control outputs
%              mOpenLoop = sCon.mCon * mPlant
%  mCloseLoop - close loop transfer at control outputs
%               mCloseLoop = inv(eye(mCon.Nout) - mOpenLoop)
%  mInOut - transfer from control inputs to control outputs with loops
%           mInOut = mCloseLoop * sCon.mCon;

function [fDC, sigDC, varargout] = parTickle(opt, pos, f)

  % === Argument Handling
  if nargin < 2
    pos = [];
  end
  if nargin < 3
    f = [];
  end

  % third argument is actually control struct (see convertSimulink)
  isCon = isstruct(f);
  if isCon
    sCon = f;
    f = sCon.f;
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
      shotPrb(k) = pQuant * (2 - sum(abs(mPrb_k), 1)) * abs(vDCin).^2;
    end
  end
  
  %%%%% compute DC outputs
  % sigDC is already real, but use "real" to remove numerical junk
  sigDC = real(mPrb(:, 1:Nfld) * vDC) / 2;
  sigQ = real(mPrbQ * vDC) / 2;
  fDC = reshape(vDC, Nlnk, Nrf);		% DC fields for output

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

  % parallel configuration (see parallel_function)
  global PARFOR_CONFIG

  PARFOR_CONFIG.minBatchSize = max(ceil(300 / Nfld), ceil(Naf / 100));
  PARFOR_CONFIG.enableWaitBar = true;
  PARFOR_CONFIG.nameWaitBar = 'parTickle';

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

  % intialize result space
  if ~isCon
    % full results: all probes, all drives
    mExc = eyeNdof(:, jDrv);

    % make batches for parallel processing
    par.sigAC = zeros(Nprb, Ndrv);
    par.mMech = zeros(Ndrv, Ndrv);
    par.noiseAC = zeros(Nprb, 1);
    par.noiseMech = zeros(Ndrv, 1);
    
    par(1:Naf) = par;
    
    % make parfor happy
    eyeNout = [];
    mPrbPrb = [];
    sCon = [];
    shotPrbAmp = [];
  else
    % reduced results for control struct
    mExc = eyeNdof(:, jDrv) * sCon.mDrvOut;

    % make batches for parallel processing
    par.mInOut = zeros(sCon.Nout, sCon.Nin);
    par.mPlant = zeros(sCon.Nin, sCon.Nout);
    par.mOpenLoop = zeros(sCon.Nout, sCon.Nout);
    par.mCloseLoop = zeros(sCon.Nout, sCon.Nout);
    par.noiseOut = zeros(sCon.Nout, 1);

    par(1:Naf) = par;
    
    % some computational aids
    eyeNout = eye(sCon.Nout);
    mPrbPrb = sCon.mPrbIn * sparse(diag(sigQ)) * sCon.mPrbOut;

    if isNoise
      shotPrbAmp = sqrt(shotPrb);
    else
      shotPrbAmp = [];
    end
  end
  
  % prevent scale warnings
  sWarn = warning('off', 'MATLAB:nearlySingularMatrix');

  %%%% audio frequency loop
  parfor nAF = 1:Naf
    
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
    if ~isCon
      % no control struct, return TFs to all probes and drives
      par(nAF).sigAC(:, :) = mPrb * tfAC(jAsb, :);
      par(nAF).mMech(:, :) = tfAC(jDrv, :);
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
      par(nAF).mInOut = mInOut;
      par(nAF).mPlant = mPlant;
      par(nAF).mOpenLoop = mOL;
      par(nAF).mCloseLoop = mCL;
    end
    
    if isNoise
      %%%% With Quantum Noise
      mQinj = [mPhim * mQuant; conj(mPhip * mQuant); mQOz];
      mNoise = (eyeNdof - mDof) \ mQinj;
      noisePrb = mPrb * mNoise(jAsb, :);
      noiseDrv = mNoise(jDrv, :);
      
      % incoherent sum of amplitude and phase noise
      if ~isCon
        par(nAF).noiseAC = sqrt(sum(abs(noisePrb).^2, 2) + shotPrb);
        par(nAF).noiseMech = sqrt(sum(abs(noiseDrv).^2, 2));
      else
        % transfer noise to outputs
        noiseAmp = mInOut * (sCon.mPrbIn * noisePrb + ...
          sCon.mDrvIn * noiseDrv);
        noisePrbAmp = mInOut * sCon.mPrbIn * shotPrbAmp;
        par(nAF).noiseOut = sqrt(sum(abs(noiseAmp).^2, 2) + ...
          abs(noisePrbAmp).^2);
      end
    end
  end
    
  % incorporate parallel results into output variables
  if ~isCon
    sigAC = cat(3, par.sigAC);
    mMech = cat(3, par.mMech);
  else
    sOpt.mInOut = cat(3, par.mInOut);
    sOpt.mPlant = cat(3, par.mPlant);
    sOpt.mOpenLoop = cat(3, par.mOpenLoop);
    sOpt.mCloseLoop = cat(3, par.mCloseLoop);
  end
  
  if isNoise
    if ~isCon
      noiseAC = cat(2, par.noiseAC);
      noiseMech = cat(2, par.noiseMech);
    else
      noiseOut = cat(2, par.noiseOut);
    end
  end
  clear par

  % reset scale warning state
  warning(sWarn.state, sWarn.identifier);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % ==== Clean Up
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % build outputs
  if ~isCon
    varargout{1} = sigAC;
    varargout{2} = mMech;
    if isNoise
      varargout{3} = noiseAC;
      varargout{4} = noiseMech;
    end
  else
    varargout{1} = sOpt;
    if isNoise
      varargout{2} = noiseOut;
    end
  end    
