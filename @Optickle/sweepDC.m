% compute signals from DC fields as a function of optic positions
%   this is a backward compatability wrapper on sweepLinear
%
% [pos, sigDC, fDC] = sweepDC(opt, posStart, posEnd, Npos)
% pos - optic position sweep (Noptic x Npos)
% sigDC - signal vectors (Nprobe x Npos)
% fDC - field matrices (Nlnk x Nrf x Npos)
%
% see also sweepLinear and sweep
%
% Example:
% opt = optFP;
% pos = zeros(opt.Noptic, 1);
% pos(getDriveIndex(opt, 'EX')) = 1e-10;
% [xpos, sigDC] = sweepDC(opt, -pos, pos, 101);

function [pos, sigDC, fDC] = sweepDC(opt, posStart, posEnd, Npos)

  Ndrv = opt.Ndrive;			% number of drives (internal DOFs)
  drvMap = getDriveMap(opt);
  nn = find(drvMap(:, 2) == 1);	% indices of drive matches
  mm = drvMap(nn, 1);			% indices of optic matches

  posStart_a = zeros(Ndrv, 1);
  posStart_a(nn) = posStart(mm);

  posEnd_a = zeros(Ndrv, 1);
  posEnd_a(nn) = posEnd(mm);
  
  [pos, sigDC, fDC] = sweepLinear(opt, posStart_a, posEnd_a, Npos);
