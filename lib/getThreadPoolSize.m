% [poolSize, isParallelSupported] = getThreadPoolSize
%   robust function for determining if parfor is supported
%   and a matlabpool is open

function [poolSize, isParallelSupported] = getThreadPoolSize
  
  if exist('parfor', 'builtin') && ...
    (exist('matlabpool', 'builtin') == 5 || ...
     exist('matlabpool', 'file') == 2)
    
    isParallelSupported = true;
    poolSize = matlabpool('size');
  else
    isParallelSupported = false;
    poolSize = 0;
  end
  
end
