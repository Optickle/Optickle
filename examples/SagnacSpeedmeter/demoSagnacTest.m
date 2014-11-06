function demoSagnacTest

  % create the model (no squeezing)
  opt = optSagnac;
  
  % get EX and EY drive indexes
  nEX = opt.getDriveIndex('EX');
  nEY = opt.getDriveIndex('EY');
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % compute the DC signals, noise and transfer functions
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % for the standard Sagnac
  f = logspace(-1, 3, 200)';
  
  pos = zeros(opt.Ndrive, 1);
  
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
  hDARM = squeeze(sigAC(nHD, nEX, :) - sigAC(nHD, nEY, :));
  
  figure;
  zplotlog(f, hDARM)
  title('Response to DARM', 'fontsize', 18);
  legend('DARM AS', 'Location', 'NorthEast');
  
  % make a noise plot
  nQuant = noiseAC(nHD, :)';
  
  figure;
  loglog(f, abs(nQuant ./ hDARM))
  title('Quantum Noise for Sagnac', 'fontsize', 18);
  grid on
end