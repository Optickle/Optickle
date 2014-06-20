% demoDetuneFP
%   this function demonstrates the use of tickle with optFP
%

function demoPolSag

  % create the model
  opt = optPolSag;
  
  % get some drive indexes
  nEX = getDriveIndex(opt, 'EX');
  nEY = getDriveIndex(opt, 'IX');

  % get some probe indexes
  nREFL_DC = getProbeNum(opt, 'REFL_DC');
  nREFL_I = getProbeNum(opt, 'REFL_I');
  nREFL_Q = getProbeNum(opt, 'REFL_Q');

  nAS_DC = getProbeNum(opt, 'AS_DC');
  nAS_I = getProbeNum(opt, 'AS_I');
  nAS_Q = getProbeNum(opt, 'AS_Q');
  
  % compute the DC signals and TFs on resonance
  f = logspace(-1, 3, 200)';
  [fDC, sigDC, sigAC, mMech, noiseAC] = tickle(opt, [], f);
  
  % Print out the fields and probes, just to demonstrate these functions:
  fprintf('DC fields (fDC matrix):\n');
  showfDC(opt, fDC);
  
  fprintf('\nProbes (sigDC matrix):\n');
  showsigDC(opt, sigDC);
  
  % make a response plot
  h0 = getTF(sigAC, nREFL_I, [nEX, nEY]);
  h1 = getTF(sigAC, nAS_I, [nEX, nEY]);
  hREFL = h0(:, 1) - h0(:, 2);
  hDARM = h1(:, 1) - h1(:, 2);
  
  figure(1)
  zplotlog(f, [h0, h1, hREFL, hDARM])
  title('PDH Response to EX and EY', 'fontsize', 18);
  legend({'EX REFL', 'EY REFL', 'EX AS', 'EY AS', 'DARM R', 'DARM AS'}, 'Location','SouthEast');
  
  % make a noise plot
  n0 = noiseAC(nREFL_I, :)';
  
  figure(2)
  loglog(f, abs(n0 ./ hDARM))
  title('Quantum Noise for Sagnac', 'fontsize', 18);
  grid on
  
end
