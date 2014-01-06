% Add a source to the model.
% Optickle currently supports only one source for the simulation.
%
% [opt, sn] = addSource(opt, name, vArf, z0, z)
% vArf - amplitudes of each RF component (Nrf x 1)
% z0 - beam range = (waist size)^2 * pi / lambda
% z - distance to waist (negative if beam is converging)
%
% Example:
% % input frequency and amplitude
% Pin = 1;				    % input power
% gMod = 0.2;				  % modulation depth
% nMod = -2:2;				% sideband indices
% vArf = sqrt(Pin) * bessel(nMod, gMod);
%
% % input basis
% z0 = 1.5e3;
% z = 0;
%
% % add the source to the Optickle model
% [opt, nSrc] = addSource(opt, 'Source', vArf, z0, z);

function [opt, sn] = addSource(opt, name, vArf, varargin)
  
  % check for old-stype 2 column frequency specification
  if size(vArf, 2) == 2 && isempty(opt.vFrf)
    warning('Using deprecated RF component specification.\n%s.', ...
            'See Optickle for more information')

    % break into frequency and amplitude vectors
    vFrf = vArf(:, 1);
    vArf = vArf(:, 2);

    % check model for existing source
    if isempty(opt.vFrf)
      opt.vFrf = vFrf;
    elseif length(vFrf) ~= length(opt.vFrf) || any(vFrf ~= opt.vFrf)
      error('Frequency vector already specified, and different.');
    end
  end
  
  if length(vArf) ~= length(opt.vFrf)
      error('RF amplitudes vector is not the right length.');
  end
      
  % add new source object
  obj = Source(name, vArf, varargin{:});
  [opt, sn] = addOptic(opt, obj);
  opt.snSource = [opt.snSource; sn];
