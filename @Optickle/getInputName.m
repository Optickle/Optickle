% str = getInputName(opt, name, inNum)

function str = getInputName(opt, name, inNum)

  sn = getSerialNum(opt, name);
  str = getInputName(opt.optic{sn}, inNum);
