% get list of drive names
%    returns a cell array of drive names
% nameList = getDriveNames(opt)

function nameList = getDriveNames(opt)
  
  nameList = cell(opt.Ndrive, 1);
  drvMap = getDriveMap(opt);
  for n = 1:opt.Ndrive
    obj = opt.optic{drvMap(n, 1)};
    nameList{n} = obj.driveNames{drvMap(n, 2)};
  end
