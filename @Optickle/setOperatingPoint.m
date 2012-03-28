% [opt, pos] = setOperatingPoint(opt, mDrive, mSense, vOffset)
% [opt, pos] = setOperatingPoint(opt, mDrive, nameErrFunc)
%   set some optic's position offsets to zero some error signals
%
% The set of error signals is determined by mSense, which should
% be Nlock x opt.Nprobe, where Nlock is the number of sensor
% signals to zero and opt.Nprobe is the number of probes in the
% model, and thus the length of sigDC (see tickle).  The drives
% used to zero the error signals are given by mDrive, which
% should be opt.Ndrive x Nlock.  An error signal offset may be
% specified in which case vErr = mSense * sigDC - vOffset.
%
% Alternately, an error function may be given which takes sigDC
% at each position (see sweep) as an argument and returns a matrix
% of error signals (one for each position).  This may be useful for
% more complex error signals which involve power normalization, etc.
%
% This is a very simple algorithm which explores with steps of
% 1e-6 * opt.lambda in each drive DOF around the start point to
% measure the response matrix, then inverts the matrix to find the
% zero crossing.  The process is repeated 10 times, or until the
% subsequent step would be less than 1e-12 * opt.lambda in all
% DOFs (taken from lockDC by Stefan Ballmer).

function [opt, pos] = setOperatingPoint(opt, varargin)

  % interpret argument
  switch length(varargin)
    case 1
      isErrFunc = true;
      nameErrFunc = varargin{1};
    case 2
      isErrFunc = false;
      mSense = varargin{2};
      mDrive = varargin{1};
      vOffset = zeros(size(mSense, 1), 1);
    case 3
      isErrFunc = false;
      mDrive = varargin{1};
      mSense = varargin{2};
      vOffset = varargin{3};
    otherwise
      error('Wrong number of input arguments')
  end

  % check Nlock
  Nlock = length(vOffset);
  if size(mSense, 1) ~= Nlock
    error('size(mSense, 1) ~= length(vOffset)');
  end
  if size(mDrive, 2) ~= Nlock
    error('size(mDrive, 2) ~= length(vOffset)');
  end
  
  % main minimization loop
  pos = zeros(opt.Ndrive, Nlock + 1);
  mOffset = repmat(vOffset, 1, Nlock + 1);
  mDelta = mDrive * 1e-6 * opt.lambda;
  for n = 1:10
    % compute sigDC at initial position plus small offsets
    pos(:, 2:end) = repmat(pos(:, 1), 1, Nlock) + mDelta;
    [fDC, sigDC] = sweep(opt, pos);
    
    % compute error signal and derivatives
    if isErrFunc
      mErr = feval(nameErrFunc, sigDC);
    else
      mErr = mSense * sigDC - mOffset;
    end
    
    vErr = mErr(:, 1);
    dmErr = mErr(:, 2:end) - repmat(vErr, 1, Nlock);
    
    % invert and set new initial position
    dpos = dmErr \ vErr;
    if ~all(isfinite(dpos))
      error('Singular matrix')
    end
    
    pos(:, 1) = pos(:, 1) - mDelta * dpos;
    
    
    if all(abs(dpos) < 1e-6)
      break
    end
  end
  
  % set positions
  pos = pos(:, 1);
  opt = addDriveOffset(opt, 1:opt.Ndrive, pos);
  