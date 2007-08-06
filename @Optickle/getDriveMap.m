% get drive map (see also getDriveNames)
%   returns Ndrive x 2 matrix
%   drvMap(:, 1) is the optic number
%   drvMap(:, 2) is the drive number for that optic
%
%
% drvMap = getDriveMap(opt)

function drvMap = getDriveMap(opt)

  drvMap = zeros(opt.Ndrive, 2);
  for n = 1:opt.Noptic
    obj = opt.optic{n};
    for m = 1:obj.Ndrive
      drvMap(obj.drive(m), 1) = n;
      drvMap(obj.drive(m), 2) = m;
    end
  end
