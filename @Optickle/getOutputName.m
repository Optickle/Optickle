% str = getOutputName(opt, name, outNum)
%   get the name of an optic's output by number

function str = getOutputName(opt, name, outNum)

  sn = getSerialNum(opt, name);
  str = getOutputName(opt.optic{sn}, outNum);
