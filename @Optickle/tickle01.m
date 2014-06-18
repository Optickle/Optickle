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
% For a half plane detector, the correction factor is sqrt(2/pi).
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


function varargout = tickle01(opt, pos, f, nDrive)

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
    [sigAC, mMech, noiseAC, noiseMech] = ...
      tickle(opt, pos, f, Optickle.tfPit, nDrive);
    varargout{1} = sigAC;
    varargout{2} = mMech;
    varargout{3} = noiseAC;
    varargout{4} = noiseMech;
  else
    [sigAC, mMech] = ...
      tickle(opt, pos, f, Optickle.tfPit, nDrive);
    varargout{1} = sigAC;
    varargout{2} = mMech;
  end
end