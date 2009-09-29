% n = getDriveNum(opt, name, driveType)
%   returns the drive index an optic,
%   given the optic's name or serial number and driveNum (optional)
%
% NOTE: driveNum can only be a single value or name
%
% see also getDriveNames and getDriveOffset

function nOut = getDriveNum(opt, name, driveType)

  % get optic serial and drive numbers
  sn = getSerialNum(opt, name);
  if nargin == 2
    driveType = 1;
  end
  
  % get drive numbers
  nOut = zeros(size(sn));
  for n = 1:numel(sn)
    dn = getDriveNum(opt.optic{sn(n)}, driveType);
    nOut(n) = opt.optic{sn(n)}.drive(dn);
  end
  
end
