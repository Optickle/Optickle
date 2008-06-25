% n = getDriveIndex(opt, name, driveType)
%   returns the drive index an optic,
%   given the optic's name or serial number and driveNum (optional)
%
% see also getDriveNames and getDriveOffset

function n = getDriveIndex(opt, name, driveType)

  % get optic serial and drive numbers
  sn = getSerialNum(opt, name);
  if nargin == 2
    driveType = 1;
  end
  
  dn = getDriveNum(opt.optic{sn}, driveType);
  n = opt.optic{sn}.drive(dn);
