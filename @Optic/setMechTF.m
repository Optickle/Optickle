% obj = setMechTF(obj, mechTF)
% 
% set the mechanical transfer functions of an optic
%
% nDOF = 1 is for position
% nDOF = 2 is for pitch

function obj = setMechTF(obj, mechTF, nDOF)

  if nargin < 3
    nDOF = 1;
  end
  
  % switch on DOF
  switch nDOF
    case 1
      obj.mechTF = mechTF;
    case 2
      obj.mechTFpit = mechTF;
    otherwise
      error('nDOF must be 1 or 2, got %d', nDOF)
  end
  