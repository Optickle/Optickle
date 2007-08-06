% [opt, sn] = addBeamSplitter(opt, name, aio, Chr, Thr, Lhr, Rar, Lmd, Nmd)
% aio - angle of incidence (in degrees)
% Chr - curvature of HR surface (Chr = 1 / radius of curvature)
% Thr - power transmission of HR suface
% Lhr - power loss on reflection from HR surface
% Rar - power reflection of AR surface
% Nmd - refractive index of medium (1.45 for fused silica, SiO2)
% Lmd - power loss in medium (one pass)
%
% see BeamSplitter and Mirror for more information

function [opt, sn] = addBeamSplitter(opt, name, varargin)

  obj = BeamSplitter(name, varargin{:});
  [opt, sn] = addOptic(opt, obj);
