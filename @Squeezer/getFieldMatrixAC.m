% getFieldMatrixAC method
% returns a mOptAC, the field transfer matrix for audio sidebands for 
% the Squeezer.  A unique function is required here because the squeezer AC
% response has off diagonal matrix elements (due to up conversion and down
% conversion of noise sidebands)
%
% mOptAC = getFieldMatrix(obj, par)


function mOptAC = getFieldMatrixAC(obj, pos, par)
  %Find the RF component which is squeezed
  [freqMatch, freqClose] = Optickle.isSameFreq(obj.nu*ones(size(par.nu)), par.nu);
  samePol = obj.pol*ones(size(par.pol))==par.pol;
  RFMat =  freqMatch & samePol;
  
  RFNonZero = find(RFMat); %Get indicies of nonzero matrix elements
  
  %Warning message of zero or n>1 RF components are squeezed
  if isempty(RFNonZero)
      warning('No RF components are being squeezed! ');
  elseif length(RFNonZero)>1
     warning('More than one RF component is being squeezed!'); 
  end
  
  % apply squeezing operator
  x = obj.x;
  %calculate squeezing factor for OPO w/o loss
  %Optickle uses the "beamsplitter model" for losses
  %The effect of losses is included later in mAC and in getNoiseMatrix.m
  %Th
  r = 0.5*log(1+4*x/(1-x)^2); 
  
  % 2x2 squeezing matrix for signal/idler pair
  % with loss = 1-escape efficiency
   mAC = sqrt(obj.escEff)*[cosh(r), -exp(i*2*obj.sqAng)*sinh(r);...
       -exp(-i*2*obj.sqAng)*sinh(r), cosh(r)];
  
  %Apply this transformation to the correct RF components
  mOptAC = eye(2*par.Nrf);
  for k=RFNonZero
      mOptAC(k,k) = mAC(1,1);
      mOptAC(k,k+par.Nrf) = mAC(1,2);
      mOptAC(k+par.Nrf,k) = mAC(2,1);
      mOptAC(k+par.Nrf,k+par.Nrf) = mAC(2,2);
  end