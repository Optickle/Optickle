% opt = setMechTF(opt, name, mechTF, nDOF)
%   set the mechanical transfer functions for an optic
% 
% name - name or serial number of an optic
% mechTF - mechanical transfer function of this optic
%
% nDOF = 1 is for position (default)
% nDOF = 2 is for pitch

function opt = setMechTF(opt, name, mechTF, nDOF)

  if nargin < 4
    nDOF = 1;
  end
  
  sn = getSerialNum(opt, name);
  opt.optic{sn} = setMechTF(opt.optic{sn}, mechTF, nDOF);
