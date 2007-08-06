% mTF = getTF(sigAC, nm)
%
% Extract transfer function vectors from sigAC.
%  nm is a Nx2 collection of from-to index pairs
%  mTF is Naf x N collection of audio-frequency response vectors
%
% Example:
%
% nm = zeros(6, 2);
% nm(1:3, 2) = getDriveIndex(opt, 'Mod1', 'amp'); % from osc amp noise
% nm(4:6, 2) = getDriveIndex(opt, 'Mod1', 'phase'); % from osc phase noise
% nm([1 4], 1) = getProbeNum(opt, 'REFL_DC');
% nm([2 5], 1) = getProbeNum(opt, 'REFL_I');
% nm([3 6], 1) = getProbeNum(opt, 'REFL_Q');
%
% mTF = getTF(sigAC, nm);
% zplotlog(f, mTF)

function mTF = getTF(sigAC, nm)

  N = size(nm, 1);
  mTF = zeros(size(sigAC, 3), N);
  for n = 1:N
    mTF(:, n) = sigAC(nm(n, 1), nm(n, 2), :);
  end
  