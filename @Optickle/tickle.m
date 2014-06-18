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


function varargout = tickle(opt, pos, f, tfType, nDrive)

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
    
    [sigAC, mMech] = tickleAC(opt, f, nDrive, vLen, ...
      vPhiGouy, mPhiFrf, mPrb, mOptGen, mRadFrc, lResp, mQuant, shotPrb);
  else
    % set the quantum scale
    pQuant  = Optickle.h * opt.nu;
    
    % compile probe shot noise vector
    shotPrb = zeros(opt.Nprobe, 1);
    
    for k = 1:opt.Nprobe
      mIn_k = prbList(k).mIn;
      mPrb_k = prbList(k).mPrb;
      
      % This section attempts to account for the shot noise due to
      % fields which are not recorded by a detector. E.g. a 10
      % MHz detector will not see signal due to 37 MHz sidebands
      % but it should see their shot noise
      shotPrb(k) = (1 - sum(abs(mPrb_k), 1)) * ...
        (pQuant .* abs(mIn_k * vDC).^2);
    end
    
    % call tickleAC to do the rest
    [sigAC, mMech, noiseAC, noiseMech] = tickleAC(opt, f, nDrive, vLen, ...
      vPhiGouy, mPhiFrf, mPrb, mOptGen, mRadFrc, lResp, mQuant, shotPrb);
  end

  % Build the rest of the outputs
  varargout{3} = sigAC;
  varargout{4} = mMech;
  if isNoise
    varargout{5} = noiseAC;
    varargout{6} = noiseMech;
  end
end
