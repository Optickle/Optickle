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

% modal stuff for next version
%  %op = inv(opt.optic(nIX).qm(2, 1).x);		% back through IX lens
%  [z0, z1] = cavHG(lCav, Ri, Re);		% cavity mode
%  op = focusOpHG(1 / Ri * 0.45);		% back through IX lens
%  op = shiftOpHG(-dSrc) * op;			% back to source
%  q = applyOpHG(op, z1 + i * z0);

function [opt, sn] = addSource(opt, name, vArf, varargin)
  
  % check model for existing source
  if opt.snSource ~= 0
    error('Source Exists: %s (%d) is the current source.\n%s', ...
          opt.optic{opt.snSource}.name, opt.snSource, ...
          'Optickle models currently support only one source.');
  end
  
  % check for old-stype 2 column frequency specification
  if size(vArf, 2) == 2 && isempty(opt.vFrf)
    warning('Using depricated RF component specification.\n%s.', ...
            'See Optickle for more information')
    opt.vFrf = vArf(:, 1);
    vArf = vArf(:, 2);
  end
  
  % add new source object
  obj = Source(name, vArf, varargin{:});
  [opt, sn] = addOptic(opt, obj);
  opt.snSource = sn;
