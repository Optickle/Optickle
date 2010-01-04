% qm = getBasisMatrix(obj)

function qm = getBasisMatrix(obj)
  
  qm = planeConvex(OpHG, obj.aoi, obj.Chr, obj.Nmd);

end
