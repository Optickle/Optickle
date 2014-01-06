% general get (For knowledgeable use only.)

function val = get(obj, str)

  if isin(obj, str)
    val = obj.(str);
  elseif isin(obj.Optic, str)
    val = obj.Optic.(str);
  else
    error(['Reference to non-existent field ''%s''' ...
      ' in object of type ''%s'''], str, class(obj));
  end
