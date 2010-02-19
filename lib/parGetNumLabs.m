% [nlabs, isPCTInstalled] = parGetNumLabs
%   get number of labs running
function [nlabs, isPCTInstalled] = parGetNumLabs
  
  % is the Parallel Computing Toolbox installed?
  %   this shouldn't change during a Matlab session, so just check once
  persistent PCT_INSTALLED
  if isempty(PCT_INSTALLED)
    PCT_INSTALLED = logical(exist('com.mathworks.toolbox.distcomp.pmode.SessionFactory', 'class'));
  end
  isPCTInstalled = PCT_INSTALLED;
  
  % if its running, how many labs are there?
  if isPCTInstalled
    nlabs = matlabpool('size');
  else
    nlabs = 0;
  end
  
end
