% set the mechanical transfer functions for an optic
% 
% opt = setMechTF(opt, name, mechTF)
% name - name or serial number of an optic
% mechTF - mechanical transfer function of this optic
%   see Mirror for more information
%
% nDOF = 1 is for position (default)
% nDOF = 2 is for pitch

function opt = setMechTF(opt, name, mechTF, nDOF)

  if nargin < 4
    nDOF = 1;
  end
  
  sn = getSerialNum(opt, name);
  opt.optic{sn} = setMechTF(opt.optic{sn}, mechTF, nDOF);
