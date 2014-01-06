% since isfield stopped working for classes

function val = isin(obj, str)

  val = any(strcmp(str, fieldnames(obj)));