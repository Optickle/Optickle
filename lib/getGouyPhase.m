% vPhiGouy = getGouyPhase(vDist, vBasis)
%   returns Gouy phase vector for beam propagation over distance
%   vDist, ending with complex basis of vBasis = z + i * z0
%
%  The Gouy phase due to propagation over distance d is
%    phi = atan(z / z0) - atan((z - d) / z0)
%  where z and z0 define the basis at the end of the propagation.
%  For a complex basis vector,
%    phi = angle(vBasis) - angle(vBasis - vDist);
%  Note that Gouy phases in Optickle are always in radians.
%
% Example, Gouy phase of each propagation step:
% opt = optFP;
% vDist = getLinkLengths(opt);
% vBasis = getAllFieldBases(opt);
% vPhiGouy = getGouyPhase(vDist, vBasis(:, 2)) * 180 / pi

function vPhiGouy = getGouyPhase(vDist, vBasis)
  
  vPhiGouy = angle(vBasis) - angle(vBasis - vDist);
