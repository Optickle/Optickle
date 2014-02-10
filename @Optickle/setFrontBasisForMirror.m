function opt = setFrontBasisForMirror(opt,sn,dWaist)
  % opt = setFrontBasisForMirror(opt,'name',dWaist)
  %   Set the distance from the beam waist to the front
  %   input of this mirror.  For non-flat mirrors,
  %   the Rayleigh Range of the input beam is given by
  %   z0 = sqrt(dWaist * (1/Chr - dWaist))
  %   The argument of the sqrt must be positive.
  %
  %   see <a href="matlab:help Mirror/setFrontBasis">Mirror.setFrontBasis</a> for more info

  if ischar(sn)
      sn = getSerialNum(opt,sn);
  end
  
  obj = opt.optic{sn};
  
  opt.optic{sn} = setFrontBasis(obj, dWaist);
end