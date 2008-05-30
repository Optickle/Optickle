% opt = addReadout(opt, name, fphi, names)
%   add a generic readout with DC and demod signals
% 
% This function adds a collection of probes at a given
% location.  The probe names are DC, I and Q.  If multiple
% demod frequency/phase pairs are given, the names are
% DC, In and Qn.  Optionally, the suffix can be specified
% with a cell array of strings.  (see also addProbeIn)
%
% name - sink name (also used as base name for probes in the readout)
% fphi - demod frequency and phase (Nx2)
% names - optional cell array of probe suffixes (instead of 1:N)

function opt = addReadout(opt, name, fphi, names)

  % break down the arguments
  N = size(fphi, 1);
  
  f = fphi(:, 1);
  phi = fphi(:, 2);
  
  % figure out the name suffix
  if nargin < 4
    if N == 1
      names = {''};
    else
      names = {};
    end
  elseif ~iscell(names)
    names = {names};
  end
  
  for n = (length(names) + 1):N
    names{n} = int2str(n);
  end

  % add DC probe
  nameDC = sprintf('%s_DC', name);
  opt = addProbeIn(opt, nameDC, name, 'in', 0, 0);

  % add demod probes
  for n = 1:N
    nameI = sprintf('%s_I%s', name, names{n});
    nameQ = sprintf('%s_Q%s', name, names{n});
    opt = addProbeIn(opt, nameI, name, 'in', f(n), phi(n));
    opt = addProbeIn(opt, nameQ, name, 'in', f(n), 90 + phi(n));
  end
  
