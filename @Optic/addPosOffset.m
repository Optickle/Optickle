% add to the position offset for an optic
% 
% obj = addPosOffset(obj, pos)

function obj = addPosOffset(obj, pos)
  if length(pos) ~= obj.Ndrive
    error('%s: drive positions not equal to number of drives (%d ~= %d)', ...
      obj.name, length(pos), obj.Ndrive);
  end
  obj.pos = obj.pos + pos;
