% returns the information about source fields
%
% vFrf - source frequency vector (Nrf x 1)
% vSrc - source amplitude vector (Nfld x 1)
%
% [vFrf, vSrc] = getSourceInfo(opt)

function [vFrf, vSrc] = getSourceInfo(opt)

  % check the source
  snSrc = opt.snSource;			% serial numbers of sources
  if isempty(snSrc)
    error('No Source: There is no field source (see addSource).');
  end

  % check frequency vector
  vFrf = opt.vFrf;			% RF frequencies
  if isempty(vFrf)
    error('There are no RF components in this model (see Optickle).')
  end
 
  % sizes of things
  Nlnk = opt.Nlink;				% number of links
  Nrf  = length(opt.vFrf);			% number of RF components
  Nsrc = length(snSrc);

  % build source vector
  vSrc = zeros(Nlnk * Nrf, 1);
  for n = 1:Nsrc
    % find source info
    obj = opt.optic{snSrc(n)};			% the source optic

    % RF amplitudes for this source
    if obj.out ~= 0
      vSrc(obj.out:Nlnk:end) = obj.vArf;
    end
  end

  % check source vector
  if sum(abs(vSrc)) == 0
    error('All sources have zero amplitude (see addSource).');
  end
