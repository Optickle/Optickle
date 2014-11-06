function demoSagnacTestSpeedmeter

  % create the model
  par = parSagnacSpeedmeterA();
  opt = optSagnacSpeedmeterA(par);
  
  % get EX and EY drive indexes
  nEX = opt.getDriveNum('M2b');
  nEY = opt.getDriveNum('M2a');
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % compute the DC signals, noise and transfer functions
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % for the standard Sagnac
  f = logspace(1, 10, 200)';
  
  pos = zeros(opt.Ndrive, 1);
  %pos(nEX) = -3.625311e-7;
  %pos(nEY) = -3.625311e-7;
  pos(nEX) = (opt.lambda(1) / 4) / cos(degtorad(par.M2b.AngleOfIncidence));
  pos(nEY) = (opt.lambda(1) / 4) / cos(degtorad(par.M2a.AngleOfIncidence));
  
  [fDC, sigDC, sigAC, ~, noiseAC] = opt.tickle(pos, f);
  
  % Print out the fields and probes, just to demonstrate these functions:
  fprintf('DC fields (fDC matrix):\n');
  showfDC(opt, fDC);
  
  fprintf('\nProbes (sigDC matrix):\n');
  showsigDC(opt, sigDC);

  nHDA_DC = opt.getProbeNum('HDA_DC');
  nHDB_DC = opt.getProbeNum('HDB_DC');
  
  % output nHDB_DC is now the difference is the homodyne difference
  %  signal, and nHDA_DC is the sum (using Optickle.mProbeOut).
  nHD = nHDB_DC;
  
  % make a response plot
  h2b = getTF(sigAC, nHD, nEX);
  h2a = getTF(sigAC, nHD, nEY);
  hDARM = squeeze(h2b - h2a);
  
  figure(1);
  zplotlog(f, [hDARM, h2a, h2b])
  title('Response to DARM', 'fontsize', 18);
  legend({'DARM AS', 'M2b', 'M2a'}, 'Location', 'NorthEast');
  
  % make a noise plot
  nQuant = noiseAC(nHD, :)';
  
  figure(2);
  loglog(f, abs(nQuant ./ hDARM))
  title('Quantum Noise for Sagnac', 'fontsize', 18);
  grid on
end