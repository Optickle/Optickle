% Compute AC transfer functions for a TEM10 mode (yaw).
%
% [sigAC, mMech] = tickle10(opt, pos, f)
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
% To convert DC signals to beam-spot motion, scale by w/(2 * Pdc),
% where w is the beam size at the probe.
%   === Thanks to Yuta Michimura!!! ===
%
% Example:
% f = logspace(0, 3, 300);
% opt = optFP;
% [sigAC, mMech] = tickle10(opt, [], f);

% 1/20/2011 N. Smith added nDrive as optional argument, allows calculation
% to be performed faster if only a subset of the drive points will be used.


function varargout = tickle10(opt, pos, f, nDrive)

  % === Argument Handling
  if nargin < 3
    error('No frequency vector given.  Use tickle for DC results.')
  end
  if nargin < 4
    nDrive = [];
  end
  
  isNoise = nargout > 2;
  
  % call tickle
  if isNoise
    [~,~,sigAC, mMech, noiseAC, noiseMech] = ...
      tickle(opt, pos, f, nDrive, Optickle.tfYaw);
    varargout{1} = sigAC;
    varargout{2} = mMech;
    varargout{3} = noiseAC;
    varargout{4} = noiseMech;
  else
    [~,~,sigAC, mMech] = ...
      tickle(opt, pos, f, nDrive, Optickle.tfYaw);
    varargout{1} = sigAC;
    varargout{2} = mMech;
  end
end