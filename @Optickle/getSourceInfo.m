% returns the information about source fields
%
% vFrf - source frequency vector (Nrf x 1)
% vSrc - source amplitude matrix (Nfld x 1)
%
% [vFrf, vSrc] = getSourceInfo(opt)

function [vFrf, vSrc] = getSourceInfo(opt)

  % check the source
  snSrc = opt.snSource;				% serial number of source
  if snSrc == 0
    error('No Source: There is no field source (see addSource).');
  end

  if isempty(snSrc)
    vFrf = opt.vFrf;			% RF frequencies
    vSrc = zeros(size(vFrf));
  else
    % find source info
    obj = opt.optic{snSrc};			% the source optic
    if obj.out == 0
      error('No Source: The field source is not linked (see addLink).');
    end

    % sizes of things
    Nlnk = opt.Nlink;				% number of links
    Nrf  = length(opt.vFrf);			% number of RF components

    % compile some info about it
    vFrf = opt.vFrf;			% RF frequencies
    vArf = obj.vArf;			% RF amplitudes for this source

    vSrc = zeros(Nlnk * Nrf, 1);
    vSrc(obj.out:Nlnk:end) = vArf;		% RF amplitude matrix
  end
