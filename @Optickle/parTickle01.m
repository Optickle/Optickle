% Compute AC transfer functions for a TEM01 mode (pitch).
%   PARALLEL VERSION - runs on the matlabpool
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


function varargout = parTickle01(opt, pos, f)

  % === Argument Handling
  if nargin < 3
    error('No frequency vector given.  Use tickle for DC results.')
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
    
    % HACK: TEM01 does not have factor of 2 for DC
    mPrb_k(mPrb_k == 2) = 1;
    
    vDCin = mIn_k * vDC;
    mPrb(k, 1:Nfld) = (mPrb_k * conj(vDCin)).' * mIn_k;
    mPrb(k, (1:Nfld) + Nfld) = (mPrb_k.' * vDCin).' * mIn_k;
  end
    
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % ==== Audio Frequency Loop
  % mostly duplicated from tickle
  %  phase includes Gouy phase
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % parallel configuration (see parallel_function)
  global PARFOR_CONFIG

  PARFOR_CONFIG.minBatchSize = max(ceil(300 / Nfld), ceil(Naf / 100));
  PARFOR_CONFIG.enableWaitBar = true;
  PARFOR_CONFIG.nameWaitBar = 'parTickle01';

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
  mExc = eyeNdof(:, jDrv);
  par.sigAC = zeros(Nprb, Ndrv);
  par.mMech = zeros(Ndrv, Ndrv);
  
  par(1:Naf) = par;
  
  % prevent scale warnings
  sWarn = warning('off', 'MATLAB:nearlySingularMatrix');

  % audio frequency loop
  parfor nAF = 1:Naf
    fAudio = f(nAF);

    % propagation phase matrices
    mPhim = getPhaseMatrix(vLen, vFrf - fAudio, -vPhiGouy); % Gouy phase has minus sign
    mPhip = getPhaseMatrix(vLen, vFrf + fAudio, -vPhiGouy);

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
    par(nAF).sigAC(:, :) = mPrb * tfAC(jAsb, :);
    par(nAF).mMech(:, :) = tfAC(jDrv, :);
  end
    
  % incorporate parallel results into output variables
  sigAC = cat(3, par.sigAC);
  mMech = cat(3, par.mMech);
  clear par
  
  % reset scale warning state
  warning(sWarn.state, sWarn.identifier);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % ==== Clean Up
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % build outputs
  varargout{1} = sigAC;
  varargout{2} = mMech;
end    
