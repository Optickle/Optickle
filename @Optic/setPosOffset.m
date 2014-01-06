% set the position offset for an optic
% 
% obj = setPosOffset(obj, pos)

function obj = setPosOffset(obj, pos)
  if length(pos) ~= obj.Ndrive
    error('%s: drive positions not equal to number of drives (%d ~= %d)', ...
      obj.name, length(pos), obj.Ndrive);
  end
  obj.pos = pos(:);
