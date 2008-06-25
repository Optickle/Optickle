% opt = setGouyPhase(opt, name, phi)
%   set Gouy phase of an existing GouyPhase object
%
% Gouy phases are expressed in radians.  see also getGouyPhase
%
% Example:
% opt = optFP;
% opt = setGouyPhase(opt, 'FakeTele', pi / 4);

function opt = setGouyPhase(opt, name, phi)

  sn = getSerialNum(opt, name);
  if isa(opt.optic{sn}, 'GouyPhase')
    opt.optic{sn} = setPhase(opt.optic{sn}, phi);
  else
    error('%s is not a GouyPhase object.', opt.optic{sn}.name);
  end
