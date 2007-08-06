% set the serial number of this optic
%  This function should only be called from @Optickle/addOptic.
%
% obj = setSN(obj, Noptic, Ndrive)

function obj = setSN(obj, sn, Ndrive)
  
  obj.sn = sn;
  obj.drive = Ndrive + (1:obj.Ndrive)';
