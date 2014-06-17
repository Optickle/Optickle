function eoDemoTestSqz
  % create model
  opt = eoOptTestSqz;
  Sqz = getOptic(opt, 'Sqz1');  %Return handle for squeezer object
  
  % get our probe index
  nSqz = getProbeNum(opt, 'Sqz_DC');
  
  % compute the quantum noise in the amplitude quadrature 
  % with various squeezing angles at 1kHz
  f = [1e3];
  SqzAngle = pi/180*[0:1:360];
  qNoise = [];
  for i=1:(length(SqzAngle));
    Sqz.sqAng = SqzAngle(i); %change squeezing angle
    [fDC, sigDC0, sigAC0, mMech0, noiseAC0] = tickle(opt, [], f);
    qNoise = cat(2,qNoise,noiseAC0);
  end
  
  % compute the unsqueezed shot noise level
  
  Sqz.setSqueezing(0, 0); %0 dB of squeezing, 0 dB of antisqueezing
  
  [fDC, sigDC0, sigAC0, mMech0, noiseAC0] = tickle(opt, [], f);
  qShot = noiseAC0;
  
  % plot the result
  plot(SqzAngle, 20*log10(qNoise/qShot))

end