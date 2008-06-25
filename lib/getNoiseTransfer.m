% vNoiseOut = getNoiseTransfer(mTF, vNoiseIn)
% vNoiseOut = getNoiseTransfer(mTF1, mTF2, ..., mTFn, vNoiseIn)
%
% Transfer noise power from incoherent sources through a Nout x Nin x Naf
% frequency dependent transfer matrix.  (see also getTF, getProdTF)
%
% The input noise power may be frequency dependent (Naf x Nin), or
% frequency independent (Nin x 1).  More generally, vNoiseIn maybe
% three dimentional of size Nin x 1 x 1 or Nin x 1 x Naf.
%
% NOTE: This transfer is for noise POWER (e.g., nAB = nA + nB).  To
% transfer noise amplitude (e.g., nAB = sqrt(nA^2 + nB^2)), use:
%   vNoiseAmpOut = sqrt(getNoiseTransfer(mTF, vNoiseAmpIn.^2));
%
% %% Example:
% vSignalNoise = getNoiseTransfer(sigAC, vDisplacementNoise);

function vNoiseOut = getNoiseTransfer(varargin)

  % get arguments
  if numel(varargin) < 2
    error('Not enough input arguments. (2 or more)')
  end
  
  vNoiseIn = varargin{end};
  if numel(varargin) > 2
    mTF = getProdTF(varargin{1:end - 1});
  else
    mTF = varargin{1};
  end
  
  % expand frequency dependent noise vectors
  if ndims(vNoiseIn) == 2 && size(vNoiseIn, 2) ~= 1
    [Nfreq, Nin] = size(vNoiseIn);
    vNoiseIn = reshape(vNoiseIn', Nin, 1, Nfreq);
  end
  
  % compute output noise
  vNoiseOut = getProdTF(abs(mTF), vNoiseIn);
