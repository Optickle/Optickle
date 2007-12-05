% Add a Gouy phase adjuster to the model.
%
% [opt, sn] = addGouyPhase(opt, name, phi)
%   phi - Gouy phase in radians, see also GouyPhase and setGouyPhase

function [opt, sn] = addGouyPhase(opt, name, varargin)

  obj = GouyPhase(name, varargin{:});
  [opt, sn] = addOptic(opt, obj);
