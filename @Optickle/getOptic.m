% Get an optic
%
% name = getOptic(opt, sn)

function obj = getOptic(opt, sn)

  sn = getSerialNum(opt, sn);
  obj = opt.optic{sn};
  
