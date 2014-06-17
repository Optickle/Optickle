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
%   === Thanks to Yuta Michimura!!! ===
%
% To convert DC signals to beam-spot motion, scale by w/(2 * Pdc),
% where w is the beam size at the probe.
%   === Thanks to Yuta Michimura!!! ===
%
% Example:
% f = logspace(0, 3, 300);
% opt = optFP;
% [sigAC, mMech] = tickle01(opt, [], f);

% 1/20/2011 N. Smith added nDrive as optional argument, allows calculation
% to be performed faster if only a subset of the drive points will be used.


function varargout = tickle01(opt, pos, f, nDrive, is10)

  % === Argument Handling
  if nargin < 3
    error('No frequency vector given.  Use tickle for DC results.')
  end
  if nargin < 4
    nDrive = [];
  end
  if nargin < 5
    is10 = 0;
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
    convertOptics01(opt, mapList, vBasis, pos, f, vDC, is10);

  % audio frequency and noise calculation
  if ~isNoise
    shotPrb = zeros(Nprb, 1);
    mQuant = zeros(Narf, 0);
    
    [sigAC, mMech] = tickleAC(opt, f, nDrive, vLen, ...
      vPhiGouy, mPhiFrf, mPrb, mOptGen, mRadFrc, lResp, mQuant, shotPrb);
  else
    [mQuant, shotPrb] = tickleNoise(opt, prbList, vDC, mQuant);
    
    [sigAC, mMech, noiseAC, noiseMech] = tickleAC(opt, f, nDrive, vLen, ...
      vPhiGouy, mPhiFrf, mPrb, mOptGen, mRadFrc, lResp, mQuant, shotPrb);
  end

  % Build the outputs
  varargout{1} = sigAC;
  varargout{2} = mMech;
  if isNoise
      varargout{3} = noiseAC;
      varargout{4} = noiseMech;
  end
end