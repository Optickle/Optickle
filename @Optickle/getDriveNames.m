% get list of drive names
%    returns a cell array of drive names
%    the format of a drive name is OpticName.DriveName
%
% nameList = getDriveNames(opt)

function nameList = getDriveNames(opt)
  
  nameList = cell(opt.Ndrive, 1);
  drvMap = getDriveMap(opt);
  for n = 1:opt.Ndrive
    obj = opt.optic{drvMap(n, 1)};
    name = obj.driveNames{drvMap(n, 2)};
    nameList{n} = [obj.name '.' name{1}];
  end
  