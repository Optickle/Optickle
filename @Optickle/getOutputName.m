% str = getOutputName(opt, name, outNum)

function str = getOutputName(opt, name, outNum)

  sn = getSerialNum(opt, name);
  str = getOutputName(opt.optic{sn}, outNum);
