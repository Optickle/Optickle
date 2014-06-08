% qm = getBasisMatrix(obj)
%
% default basis matrix: no basis change

function qm = getBasisMatrix(obj)
  
  qm = repmat(OpHG, obj.Nin, obj.Nout);
