% not working

function qm = getBasisMatrix(obj)
  
  % ======== Compute Basis Transform Matrix
  qm = repmat(OpHG, 8, 4);
  q0 = planeConvex(OpHG, obj.aoi, obj.Chr, obj.Nmd);
  qm(1:4, 1:2) = q0;
  qm(5:8, 3:4) = q0;
