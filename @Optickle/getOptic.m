% obj = getOptic(opt, name)
%   Get an optic by name

function obj = getOptic(opt, name)

  sn = getSerialNum(opt, name);
  obj = opt.optic{sn};
  
