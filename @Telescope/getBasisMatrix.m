% qm = getBasisMatrix(obj)

function qm = getBasisMatrix(obj)
  
  qm = focus(OpHG, 1 ./ obj.f);
  df = obj.df;
  for n = 1:size(df, 1)
    qm = shift(qm, df(n, 1));
    qm = focus(qm, 1 ./ df(n, 2));
  end
  