% vDist = getLinkLengths(opt)
%   returns the lengths of each link
%
% %% Example, Gouy phase of each propagation step:
% opt = optFP;
% vDist = getLinkLengths(opt);
% vBasis = getAllFieldBases(opt);
% vPhiGouy = getGouyPhase(vDist, vBasis(:, 2)) * 180 / pi

function vDist = getLinkLengths(opt)

  lnks = opt.link;
  vDist = [lnks.len]';
  