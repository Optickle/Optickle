% general set (For knowledgeable use only.)

function obj = set(obj, str, val)

  if isin(obj, str)
    obj.(str) = val;
  elseif isin(obj.Optic, str)
    obj.Optic = set(obj.Optic, str, val);
  else
    error(['Reference to non-existent field ''%s''' ...
      ' in object of type ''%s'''], str, class(obj));
  end
