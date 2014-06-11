% getFieldMatrixAC method
% returns a mOptAC, the field transfer matrix for audio sidebands for this optic
%
% mOptAC = getFieldMatrix(obj, par)


function mOptAC = getFieldMatrixAC(obj, pos, par)
  
  % account for losses
  mLoss = blkdiagN(sqrt(1-obj.loss), 2*par.Nrf);
  
  % apply squeezing operator
  r = obj.SQZdB*(ln(10)/20) %calculate squeezing factor
  mSqz = [cosh(r), -exp(i*2*par.SqzAng)*sinh(r); -exp(-i*2*par.SqzAng)*sinh(r), cosh(r)];
  mOptAC = obj.
   