% DEPRECATED - use getSourceInfo
%
% returns the field source for this Optickle model,
% and some information about it.
%
% vFrf - source frequency vector (Nrf x 1)
% vArf - source amplitude vector (Nrf x 1)
% mSrc - source amplitude matrix (Nfld x Nrf)
% nSrc - source field index
%
% [vFrf, vArf, mSrc, nSrc] = getFieldSource(opt)

function [vFrf, vArf, mSrc, nSrc] = getFieldSource(opt)

  % check the source
  snSrc = opt.snSource;				% serial number of source
  if snSrc == 0
    error('No Source: There is no field source (see addSource).');
  end
  
  optSrc = opt.optic{snSrc};			% the source optic
  if optSrc.out == 0
    error('No Source: The field source is not linked (see addLink).');
  end

  % sizes of things
  Nlnk = opt.Nlink;				% number of links
  Nrf  = length(opt.vFrf);			% number of RF components

  % compile some info about it
  vFrf = opt.vFrf;			% RF frequencies
  vArf = optSrc.vArf;			% RF amplitudes
  nSrc = optSrc.out;				% index of source field

  mSrc = zeros(Nlnk, Nrf);
  mSrc(nSrc, :) = vArf';		% RF amplitude matrix
  
  if nargout == 4
    warning('Using deprecated output nSrc')
  end
