% opt = setGouyPhase(opt, name, phi)
%   set Gouy phase of an existing GouyPhase object

function opt = setGouyPhase(opt, name, phi)

  sn = getSerialNum(opt, name);
  if isa(opt.optic{sn}, 'GouyPhase')
    opt.optic{sn} = setPhase(opt.optic{sn}, phi);
  else
    error('%s is not a GouyPhase object.', opt.optic{sn}.name);
  end
