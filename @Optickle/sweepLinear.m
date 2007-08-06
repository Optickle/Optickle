% compute signals from DC fields as a function of optic positions
%
% [pos, sigDC, fDC] = sweepLinear(opt, posStart, posEnd, Npos)
% pos - optic position sweep (Ndrive x Npos)
% sigDC - signal vectors (Nprobe x Npos)
% fDC - field matrices (Nlink x Nrf x Npos)
%
% see also sweep
%
% Example:
% opt = optFP;
% pos = zeros(opt.Ndrive, 1);
% pos(getDriveIndex(opt, 'EX')) = 1e-10;
% [xpos, sigDC] = sweepLinear(opt, -pos, pos, 101);

function [pos, sigDC, fDC] = sweepLinear(opt, posStart, posEnd, Npos)

  % generate position vectors
  x = (0:Npos-1)' / (Npos - 1);
  dpos = posEnd - posStart;
  pos = zeros(opt.Ndrive, Npos);			% optic positions
  for n = 1:Npos
    pos(:, n) = dpos * x(n) + posStart;
  end

  % sweep
  [fDC, sigDC] = sweep(opt, pos);
