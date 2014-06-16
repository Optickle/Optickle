function eoDemoTestSqz
  % create model
  opt = eoOptTestSqz;
  
  % get our probe index
  nSqz = getProbeNum(opt, 'Sqz_DC');
  
  % compute the quantum noise in the amplitude quadrature 
  % with various squeezing angles at 1kHz
  f = [1e3];
  SqzAngle = pi/180*[0:1:360];
  qNoise = [];
  for i=1:(length(SqzAngle));
    opt = setOpticParam(opt, 'Sqz1', 'sqAng', SqzAngle(i));
    [fDC, sigDC0, sigAC0, mMech0, noiseAC0] = tickle(opt, [], f);
    qNoise = cat(2,qNoise,noiseAC0);
  end
  
  % compute the unsqueezed shot noise level
  % Changing the level of squeezing/antisqueezing clearly needs its own function
  % to recalculate x and etaEsc.  Fix this later!
  
  setOpticParam(opt, 'Sqz1', 'sqdB', 0);  %Set squeezing to 0 dB
  setOpticParam(opt, 'Sqz1', 'antidB', 0);  %Set anti squeezing to 0 dB
  setOpticParam(opt, 'Sqz1', 'x', 0);
  setOpticParam(opt, 'Sqz1', 'escEff', 1); 
  [fDC, sigDC0, sigAC0, mMech0, noiseAC0] = tickle(opt, [], f);
  qShot = noiseAC0;
  
  % plot the result
  plot(SqzAngle, 20*log10(qNoise/qShot))

end