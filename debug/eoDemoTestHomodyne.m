function eoDemoTestHomodyne
  % create model
  opt = eoOptTestHomodyne;
  Sqz = getOptic(opt,'Sqz1');
  
  % set the probe matrix---> Takes "Probes" to "Outputs"
  opt.mProbeOut = [1 1; 1 -1]; %first row is HD sum, second is HD difference
  
  % get our drive index
  nDrv = getDriveNum(opt,'HDBS');
  
  % compute the quantum noise for various quadratures 
  % with various squeezing angles at 1kHz
  f = 1e3;
  posHD = 1064e-9/360*[0:1:360]/sqrt(2); %Changing the "Homodyne Angle"
  SqzAngle = pi/180*[0:1:360];
  qNoise = [];
  pos = zeros(opt.Ndrive,1);
  for i=1:(length(posHD));
    pos(nDrv) = posHD(i);
    [fDC, sigDC0, sigAC0, mMech0, noiseAC0] = tickle(opt, pos, f);
    qNoise = cat(2,qNoise,noiseAC0(2));  %quantum noise for HD diff output
  end
  
  % compute the unsqueezed shot noise level
  
  Sqz.setSqueezing(0, 0); %0 dB of squeezing, 0 dB of antisqueezing
  
  [fDC, sigDC0, sigAC0, mMech0, noiseAC0] = tickle(opt, [], f);
  qShot = noiseAC0(2);
  
  % plot the result
  plot(SqzAngle, 20*log10(qNoise/qShot))

end