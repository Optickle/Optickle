% rslt = getProdTF(lhs, rhs, ...)
%
% Compute the product of 2 or more Nout x Nin x Naf
% frequency dependent transfer matrices.  (see also getTF)
%
% NOTE: To perform more complicated operations on transfer
%       matrices, see LTI object FRD ("help frd").  This
%       function is the same as: freqresp(frd(lhs) * frd(rhs), f)
%
% %% Example:
% mOL = getProdTF(mCtrl, sigAC);

function rslt = getProdTF(lhs, rhs, varargin)

  % deal with multiple arguments recursively
  if numel(varargin) > 0
    rhs = getProdTF(rhs,  varargin{:});
  end
  
  % check matrix size
  if( size(lhs, 2) ~= size(rhs, 1) )
    error('Matrix size mismatch size(lhs, 2) = %d ~= %d = size(rhs, 1)', ...
      size(lhs, 2), size(rhs, 1))
  end
  N = size(lhs, 1);
  M = size(rhs, 2);
  
  % compute product
  if( size(lhs, 3) == 1 )
    Nfreq = size(rhs, 3);
    rslt = zeros(N, M, Nfreq);
    for n = 1:Nfreq
      rslt(:, :, n) = lhs * rhs(:, :, n);
    end
  elseif( size(rhs, 3) == 1 )
    Nfreq = size(lhs, 3);
    rslt = zeros(N, M, Nfreq);
    for n = 1:Nfreq
      rslt(:, :, n) = lhs(:, :, n) * rhs;
    end
  elseif( size(lhs, 3) == size(rhs, 3) )
    Nfreq = size(lhs, 3);
    rslt = zeros(N, M, Nfreq);
    for n = 1:Nfreq
      rslt(:, :, n) = lhs(:, :, n) * rhs(:, :, n);
    end
  else
    error('Matrix size mismatch size(lhs, 3) = %d ~= %d = size(rhs, 3)', ...
      size(lhs, 3), size(rhs, 3))
  end
