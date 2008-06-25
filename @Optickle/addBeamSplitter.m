% [opt, sn] = addBeamSplitter(opt, name, aio, Chr, Thr, Lhr, Rar, Lmd, Nmd)
%
% ===> Do not waste time with BeamSplitters <===
% A BeamSplitter is a 4 input, 8 output object designed to be used
% where fields propagating in opposite directions overlap on the same
% optic (e.g., in an interferometer).  If you are simply splitting a
% beam among detectors you need only one input and 2 outputs, so a
% Mirror object is sufficient, will reduce complexity as it does not
% have A and B sides, and will save computation time.  Typically, an
% interferometer simulation, including readout, requires only ONE
% BeamSplitter object.
%
% aio - angle of incidence (in degrees)
% Chr - curvature of HR surface (Chr = 1 / radius of curvature)
% Thr - power transmission of HR surface
% Lhr - power loss on reflection from HR surface
% Rar - power reflection of AR surface
% Nmd - refractive index of medium (1.45 for fused silica, SiO2)
% Lmd - power loss in medium (one pass)
%
% see BeamSplitter and Mirror for more information

function [opt, sn] = addBeamSplitter(opt, name, varargin)

  obj = BeamSplitter(name, varargin{:});
  [opt, sn] = addOptic(opt, obj);
