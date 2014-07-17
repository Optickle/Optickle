% Compute DC fields, and DC signals, and AC transfer functions
%
% [fDC, sigDC, mOpt, mMech, noiseAC, noiseMech] = ...
%   tickle2(opt, pos, f, tfType, nDrive)
% opt       - Optickle model
% pos       - optic positions (Ndrive x 1, or empty)
% f         - audio frequency vector (Naf x 1, default is [])
% tfType    - specify position, pitch or yaw transfer function
%             (i.e., TEM00, TEM01 or TEM10).  Use the class
%             constants Optickle.tfPos, tfPit or tfYaw (default is tfPos).
% nDrive    - drive indices to consider (Nx1, default is all)
%             NOTE: this _overwrites_ the opt.mInDrive matrix
%
% fDC       - DC fields at this position (Nlink x Nrf)
%             where Nlink is the number of links, and Nrf
%             is the number of RF frequency components.
% sigDC     - DC signals for each probe (Nprobe x 1)
%             where Nprobe is the number of probes.
% mOpt      - optical transfer matrix (Nout x Nin x Naf),
%             where Nin is the total number of optic drive
%             inputs (e.g., 1 for a mirror, 2 for a RFmodulator).
%             Thus, sigAC is arranged such that sigAC(n, m, :)
%             is the TF from input m to output n.
%             NOTE: if mProbeOut is empty, the outputs are all probes
%               similarly, if mInDrv is empty, the inputs are all drives
% mMech     - opto-mechanical modification of the inputs (Nin x Nin x Naf)
%             if there are no opto-mechanics, this will be the identity.
%             NOTE: mMech does NOT include the mechanical response to
%             force (i.e., MechTF).
%
% noiseOut   - quantum noise at each output/probe (Nout x Naf)
% noiseMech - quantum noise at each input/drive (Nin x Naf)
%
% UNITS:
% Assuming the input laser power is in Watts, and laser wavelength is in
% meters, the outputs are generically 
% fDC   - [sqrt(W)]
% sigDC - [W]
% mOpt - [W/m]  assuming the drive is a mirror. 
%  If the drive is a modulator, then mOpt is [W/AM] or [W/rad] for
%  an amplitude or phase modulation, respectively.  Generally, the
%  units are W/(drive unit).
% mMech - [m/m]  again, generally this is (drive unit)/(drive unit)
%
% NOTE: tickle2 will use parallel workers (see parpool)
%
% EXAMPLE:
% f = logspace(0, 3, 300);
% opt = optFP;
% [fDC, sigDC, mOpt, mMech] = tickle2(opt, [], f);
%
% EXAMPLE (parallel):
% gcp; % start parallel worker pool
% f = logspace(0, 3, 3000);
% opt = optFP;
% [fDC, sigDC, mOpt, mMech, noiseOpt] = tickle2(opt, [], f);
%
% (see also @Optickle/Optickle, parpool)


function varargout = tickle2(opt, pos, f, tfType, nDrive)

  % === Argument Handling
  if nargin < 2
    pos = [];
  end
  if nargin < 3
    f = [];
  end
  if nargin < 4
    tfType = Optickle.tfPos;
  end
  if nargin < 5
    nDrive = [];
  end

  % implement nDrive
  if ~isempty(nDrive)
    % make input matrix for this nDrive
    jDrv = 1:opt.Ndrive;
    eyeNdrv = eye(opt.Ndrive);
    opt.mInDrive = eyeNdrv(:, jDrv(nDrive));
  end
    
    
  % === Field Info
  vFrf = opt.vFrf;
  
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
  isNoise = isAC && (nargout > 4);

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
  
  % check tfType
  if ~(tfType == Optickle.tfPos || ...
      tfType == Optickle.tfPit || tfType == Optickle.tfYaw)
    error('tfType argument invalid.  Must be Optickle.tfXXX')
  end

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
  
  [vLen, prbList, mapList, mPhiFrf, vDC, mPrb, mPrbQ] = ...
    tickleDC(opt, pos);

  %%%%% compute DC outputs
  % sigDC is already real, but use "real" to remove numerical junk
  sigDC = real(mPrb * vDC);
  fDC = reshape(vDC, Nlnk, Nrf);		% DC fields for output

  %sigQ = real(mPrbQ * vDC);  % will need this for osc phase noise!
  
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
  
  % check for TEM01 or TEM10 call
  if tfType ~= Optickle.tfPos
    % get basis vector
    vBasis = getAllFieldBases(opt);
    
    % Gouy phases... take y-basis for TEM01 mode (pitch)
    lnks = opt.link;
    vDist = [lnks.len]';
    
    % get Gouy phase for pitch or yaw
    if tfType == Optickle.tfPit
      % take y-basis for TEM01 mode (pitch)
      vPhiGouy = getGouyPhase(vDist, vBasis(:, 2));
    else
      % take x-basis for TEM10 mode (pitch)
      vPhiGouy = getGouyPhase(vDist, vBasis(:, 1));
    end
    
    % scale outputs by half-plane overlap integral
    modeOverlapFactor = sqrt(2 / pi); % Overlap integral of 01/10
                                      % with 00 mode on split diode
    mPrb = modeOverlapFactor * mPrb;
  else
    % TEM00, so no basis or Gouy phase
    vBasis = [];
    vPhiGouy = [];
  end
  
  % expand the probe matrix to both audio SBs
  mPrb = sparse([mPrb, conj(mPrb)]);
  
  % get optic matricies for AC part
  [mOptGen, mRadFrc, lResp, mQuant] = ...
    convertOpticsAC(opt, mapList, pos, f, vDC, tfType, vBasis);

  % audio frequency and noise calculation
  if ~isNoise
    % no noise calculation... easy!
    shotPrb = zeros(Nprb, 1);
    mQuant = zeros(Narf, 0);
    
    % call tickleAC to do the rest
    if exist('gcp', 'file') == 2 && ~isempty(gcp('nocreate'))
      % try to run in parallel
      [mOpt, mMech] = tickleACpar(opt, f, vLen, vPhiGouy, ...
        mPhiFrf, mPrb, mOptGen, mRadFrc, lResp, mQuant, shotPrb);
    else
      [mOpt, mMech] = tickleAC(opt, f, vLen, vPhiGouy, ...
        mPhiFrf, mPrb, mOptGen, mRadFrc, lResp, mQuant, shotPrb);
    end
  else
    % set the quantum scale
    pQuant  = Optickle.h * opt.nu;
    
    % compile probe shot noise vector
    shotPrb = zeros(opt.Nprobe, 1);
    
    for k = 1:opt.Nprobe
      mIn_k = prbList(k).mIn;
      mPrb_k = prbList(k).mPrb;
      
      % This section accounts for the shot noise due to
      % fields which are not recorded by a detector. For instance,
      % a 10 MHz detector will not see signal due to 37 MHz
      % sidebands, but it should see their shot noise.
      shotPrb(k) = (1 - sum(abs(mPrb_k), 1)) * ...
        (pQuant .* abs(mIn_k * vDC).^2);
    end
    
    % call tickleAC to do the rest
    if exist('gcp', 'file') == 2 && ~isempty(gcp('nocreate'))
      % try to run in parallel
      [mOpt, mMech, noiseAC, noiseMech] = tickleACpar(opt, f, vLen, ...
        vPhiGouy, mPhiFrf, mPrb, mOptGen, mRadFrc, lResp, mQuant, shotPrb);
    else
      [mOpt, mMech, noiseAC, noiseMech] = tickleAC(opt, f, vLen, ...
        vPhiGouy, mPhiFrf, mPrb, mOptGen, mRadFrc, lResp, mQuant, shotPrb);
    end
  end

  % Build the rest of the outputs
  varargout{3} = mOpt;
  varargout{4} = mMech;
  if isNoise
    varargout{5} = noiseAC;
    varargout{6} = noiseMech;
  end
end
