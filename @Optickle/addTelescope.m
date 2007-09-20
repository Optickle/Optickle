% [opt, sn] = addTelescope(opt, name, f)
% [opt, sn] = addTelescope(opt, name, f, df)
%   Add a Telescope to the model.
%
% name - name of this optic
% f - focal length of first lens
% df - distances from previous lens and lens focal length
%      for lenses after the first
%
% see Telescope for more information

function [opt, sn] = addTelescope(opt, name, varargin)

  obj = Telescope(name, varargin{:});
  [opt, sn] = addOptic(opt, obj);
