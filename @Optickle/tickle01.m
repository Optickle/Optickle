% Compute AC transfer functions for a TEM01 mode (pitch).
%
% [sigAC, mMech] = tickle01(opt, pos, f)
% opt - Optickle model
% pos - optic positions (Ndrive x 1, or empty)
% f - audio frequency vector (Naf x 1)
%
% sigAC - transfer matrix (Nprobe x Ndrive x Naf),
%   where Ndrive is the total number of optic drive
%   inputs (e.g., 1 for a mirror, 2 for a RFmodulator).
%   Thus, sigAC is arranged such that sigAC(n, m, :)
%   is the TF from the drive m to probe n.
% mMech - modified drive transfer functions (Ndrv x Ndrv x Naf)
%
% Example:
% f = logspace(0, 3, 300);
% opt = optFP;
% [sigAC, mMech] = tickle01(opt, [], f);


% %%%%%%%%%%%%%%%%%%%% With control struct
% sOpt = tickle(opt, pos, sCon)
%
% An alternate means of using tickle01 is to pass a control struct
% as the third argument.  See tickle and convertSimulink for details.
%
% As with tickle, but for the pitch degree-of-freedom, the result is
% Optickle system struct which contains the following fields:
%   mPlant - transfer from control outputs to control inputs
%            this is taken from sigAC and mMech
%   mOpenLoop - open loop tranfer at control outputs
%               mOpenLoop = sCon.mCon * mPlant
%   mCloseLoop - close loop transfer at control outputs
%                mCloseLoop = inv(eye(mCon.Nout) - mOpenLoop)
%   mInOut - transfer from control inputs to control outputs with loops
%            mInOut = mCloseLoop * sCon.mCon;

function varargout = tickle01(opt, pos, f)

  % === Argument Handling
  if nargin < 3
    error('No frequency vector given.  Use tickle for DC results.')
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
  % ==== Convert to Matrix Form
  % duplicated from tickle
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % link and probe conversion
  [vLen, prbList, mapList] = convertLinks(opt);
  
  % get basis vector
  vBasis = getAllFieldBases(opt);
  
  % Gouy phases... take y-basis for TEM01 mode (pitch)
  lnks = opt.link;
  vDist = [lnks.len]';
  vPhiGouy = getGouyPhase(vDist, vBasis(:, 2));

  % optic conversion
  mOpt = convertOptics(opt, mapList, pos, []);
  [m01, rctList, drvList] = convertOptics01(opt, mapList, vBasis, pos, f);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % ==== DC Fields and Signals
  % duplicated from tickle
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % compute DC fields
  eyeNfld = speye(Nfld);			% a sparse identity matrix
  mPhi = getPhaseMatrix(vLen, vFrf);		% propagation phase matrix
  vDC = (eyeNfld - (mPhi * mOpt)) \ (mPhi * vSrc);

  % compile system wide probe matrix and probe shot noise vector
  mPrb = sparse(Nprb, Narf);
  for k = 1:Nprb
    mIn_k = prbList(k).mIn;
    mPrb_k = prbList(k).mPrb;
    
    vDCin = mIn_k * vDC;
    mPrb(k, 1:Nfld) = (mPrb_k * conj(vDCin)).' * mIn_k;
    mPrb(k, (1:Nfld) + Nfld) = (mPrb_k.' * vDCin).' * mIn_k;
  end
    
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % ==== Audio Frequency Loop
  % mostly duplicated from tickle
  %  phase includes Gouy phase
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
  eyeNdof = speye(Ndof);

  % intialize result space
  if ~isCon
    % full results: all probes, all drives
    mExc = eyeNdof(:, jDrv);
    sigAC = zeros(Nprb, Ndrv, Naf);
    mMech = zeros(Ndrv, Ndrv, Naf);
  else
    % reduced results for control struct
    mExc = eyeNdof(:, jDrv) * sCon.mDrvOut;

    sOpt.mInOut = zeros(sCon.Nout, sCon.Nin, Naf);
    sOpt.mPlant = zeros(sCon.Nin, sCon.Nout, Naf);
    sOpt.mOpenLoop = zeros(sCon.Nout, sCon.Nout, Naf);
    sOpt.mCloseLoop = zeros(sCon.Nout, sCon.Nout, Naf);
    
    eyeNout = eye(sCon.Nout);
    mPrbPrb = sCon.mPrbIn * sparse(diag(sigQ)) * sCon.mPrbOut;
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
    mPhim = getPhaseMatrix(vLen, vFrf - fAudio, vPhiGouy);
    mPhip = getPhaseMatrix(vLen, vFrf + fAudio, vPhiGouy);

    % field to optic position transfer
    mFOm = rctList(nAF).m * conj(mDC) / LIGHT_SPEED;
    mFOp = rctList(nAF).m * mDC / LIGHT_SPEED;

    % field to field transfer
    mFFm = mPhim * m01;
    mFFp = conj(mPhip * m01);

    % optic to field transfer
    mOFm = mPhim * mGen;
    mOFp = conj(mPhip * mGen);
    
    % ==== Put it together and solve
    mDof = [mFFm, mFFz, mOFm; mFFz, mFFp, mOFp; mFOm, mFOp, mOOz];
    tfAC = (eyeNdof - mDof) \ mExc;

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

  % build outputs
  if ~isCon
    varargout{1} = sigAC;
    varargout{2} = mMech;
  else
    varargout{1} = sOpt;
  end    