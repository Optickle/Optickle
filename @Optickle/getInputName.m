% str = getInputName(opt, name, inNum)
%   get the name of an optic's input, given its number

function str = getInputName(opt, name, inNum)

  sn = getSerialNum(opt, name);
  str = getInputName(opt.optic{sn}, inNum);
