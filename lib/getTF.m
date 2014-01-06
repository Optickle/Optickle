% mTF = getTF(sigAC, nm)
% mTF = getTF(sigAC, n, m)
%
% Extract transfer function vectors from sigAC, or similar
% Nout x Nin x Naf frequency dependent transfer matrix.
%  nm is a Nx2 collection of from-to index pairs
%  n is a Nx1 collection of output indices, or single index
%  m is a Nx1 collection of input indices, or single index
%
%  mTF is Naf x N collection of audio-frequency response vectors
%
% NOTE: To perform more complicated operations on transfer
%       matrices, see LTI object FRD ("help frd").
%
% %% Example, from input 5 to outputs 1, 2 and 3:
% mTF = getTF(sigAC, 1:3, 5);
%
% %% Example, from Mod1 amp and phase to REFL signals:
% nm = zeros(6, 2);
% nm(1:3, 2) = getDriveIndex(opt, 'Mod1', 'amp'); % from osc amp noise
% nm(4:6, 2) = getDriveIndex(opt, 'Mod1', 'phase'); % from osc phase noise
% nm([1 4], 1) = getProbeNum(opt, 'REFL_DC');
% nm([2 5], 1) = getProbeNum(opt, 'REFL_I');
% nm([3 6], 1) = getProbeNum(opt, 'REFL_Q');
%
% mTF = getTF(sigAC, nm);
% zplotlog(f, mTF)

function mTF = getTF(sigAC, nm, m)

  % figure out arguments
  if nargin == 3
    if length(nm) ~= numel(nm)
      error('Third argument with non-vector first argument... what to do?');
    end
    
    % vectorize
    m = m(:);
    nm = nm(:);
    
    % deal with scalars
    if length(m) == length(nm)
      nm = [nm, m];
    elseif length(m) == 1
      nm = [nm, m * ones(size(nm))];
    else
      nm = [nm * ones(size(m)), m];
    end
  end

  N = size(nm, 1);
  mTF = zeros(size(sigAC, 3), N);
  for n = 1:N
    mTF(:, n) = sigAC(nm(n, 1), nm(n, 2), :);
  end
  