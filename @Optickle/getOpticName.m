% Get the name of an optic
%
% name = getOpticName(opt, sn)

function name = getOpticName(opt, sn)

  sn = getSerialNum(opt, sn);
  name = opt.optic{sn}.name;
  
