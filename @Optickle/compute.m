% Compute field propagation matrix
%   This is a backward compatability wrapper for tickle.
%   It uses getDriveMap to map the drives used by tickle to the old
%   "one optic, one drive" convention.  fAC is not computed.
%
% [sigDC, sigAC, mMech, fDC] = compute(opt, pos, f)
%
% opt - Optickle model
% pos - optic positions (Noptic x 1, or empty for zero)
% f - audio frequency vector (Naf x 1)
%
% fDC - DC fields at this position (Nlink x Nrf)
% sigDC - DC signals for each probe (Nprobe x 1)
% sigAC - transfer matrix (Nprobe x Noptic x Naf)
% mechTF - modified drive transfer functions (Noptic x Noptic x Naf)
%
% see also tickle
%
% Example:
% f = logspace(0, 3, 300);
% opt = optFP;
% [sigDC, sigAC] = compute(opt, [], f);

function [sigDC, sigAC, mechTF, fDC, fAC] = compute(opt, pos, f)

  % let the user know that this is old
  warning('Using depricated COMPUTE function.\n%s.', ...
    'Please use TICKLE to avoid drive number confusion.')

  % sizes of things
  Nopt = opt.Noptic;			% number of optics
  Ndrv = opt.Ndrive;			% number of drives (internal DOFs)
  Nprb = opt.Nprobe;			% number of probes
  Naf = length(f);

  drvMap = getDriveMap(opt);
  nn = find(drvMap(:, 2) == 1);	% indices of drive matches
  mm = drvMap(nn, 1);			% indices of optic matches

  % position given for each optic, convert to each drive
  if isempty(pos)
    pos_a = [];
  else
    pos_a = zeros(Ndrv, 1);
    pos_a(nn) = pos(mm);
    for n = 1:Nopt
      if opt.optic{n}.Ndrive == 0 && pos(n) ~= 0
        error('Non-zero position given for %d of type %s (no drive).', ...
          n, class(opt.optic{n}));
      end
    end
  end
  
  % tickle
  [fDC, sigDC, sigACa, mMech] = tickle(opt, pos_a, f);

  % convert mMech and sigAC to optic from drive
  sigAC = zeros(Nprb, Nopt, Naf);
  eyeNopt = eye(Nopt);
  mechTF = repmat(eyeNopt, [1, 1, Naf]);
  if Naf > 0
    sigAC(:, mm, :) = sigACa(:, nn, :);
    mechTF(mm, mm, :) = mMech(nn, nn, :);
  end
  
  % fAC is not computed
  fAC = [];
