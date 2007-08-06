% set the mechanical transfer functions for an optic
% 
% opt = setMechTF(opt, name, mechTF)
% name - name or serial number of an optic
% mechTF - mechanical transfer functions of this optic
%   see Mirror for more information

function opt = setMechTF(opt, name, mechTF)

  sn = getSerialNum(opt, name);
  opt.optic{sn} = setMechTF(opt.optic{sn}, mechTF);
