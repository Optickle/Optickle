% demoSagnac
%   this function demonstrates the use of tickle with a Sagnac Interferometer
%

function demoSagnac

  % create the model (no squeezing)
  opt = optSagnac;
  
  % get some drive indexes
  nBS = opt.getDriveIndex('BS');
  nCM = opt.getDriveIndex('CM');
  nEX = opt.getDriveIndex('EX');
  nEY = opt.getDriveIndex('EY');

  % get some probe indexes
  nREFL_DC = opt.getProbeNum('REFL_DC');
  nREFL_I = opt.getProbeNum('REFL_I');
  nREFL_Q = opt.getProbeNum('REFL_Q');

  nHDA_DC = opt.getProbeNum('HDA_DC');
  nHDB_DC = opt.getProbeNum('HDB_DC');
  
  % output nHDB_DC is now the difference is the homodyne difference
  %  signal, and nHDA_DC is the sum (using Optickle.mProbeOut).
  nHD = nHDB_DC;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % compute the DC signals, noise and transfer functions
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % for the standard Sagnac
  f = logspace(-1, 3, 200)';
  [fDC, sigDC, sigAC, ~, noiseOpt] = opt.tickle([], f);
  
  % compute the same with squeezing (squeeze angle = 0)
  opt = optSagnac(0, 6, 10);
  [~, ~, ~, ~, noiseSqz00] = opt.tickle([], f);
  
  % compute the same with squeezing (squeeze angle = 45)
  opt = optSagnac(pi / 4, 6, 10);
  [~, ~, ~, ~, noiseSqz45] = opt.tickle([], f);
  
  % compute the same with squeezing (squeeze angle = 90)
  opt = optSagnac(pi / 2, 6, 10);
  [~, ~, ~, ~, noiseSqz90] = opt.tickle([], f);
  
  % compute the same with squeezing (squeeze angle = 135)
  opt = optSagnac(3 * pi / 4, 6, 10);
  [~, ~, ~, ~, noiseSqz135] = opt.tickle([], f);
  
  % Print out the fields and probes, just to demonstrate these functions:
  fprintf('DC fields (fDC matrix):\n');
  showfDC(opt, fDC);
  
  fprintf('\nProbes (sigDC matrix):\n');
  showsigDC(opt, sigDC);
  
  % make a response plot
  h0 = getTF(sigAC, nREFL_I, [nEX, nEY]);
  h1 = getTF(sigAC, nHD, [nEX, nEY]);
  hREFL = h0(:, 1) + h0(:, 2);
  hDARM = h1(:, 1) - h1(:, 2);
  
  figure(1)
  zplotlog(f, [hREFL, hDARM])
  title('Response to CARM and DARM', 'fontsize', 18);
  legend({'CARM REFL', 'DARM AS'}, 'Location','NorthEast');
  
%  zplotlog(f, [h0, h1])
%  title('Response to EX and EY', 'fontsize', 18);
%  legend({'EX R', 'EY R', 'EX AS', 'EY AS'}, 'Location','NorthEast');
  
  % make a noise plot
  nNoSqz = noiseOpt(nHD, :)';
  nSqz00 = noiseSqz00(nHD, :)';
  nSqz45 = noiseSqz45(nHD, :)';
  nSqz90 = noiseSqz90(nHD, :)';
  nSqz135 = noiseSqz135(nHD, :)';
  
  figure(2)
  loglog(f, abs([nNoSqz ./ hDARM, nSqz00 ./ hDARM, ...
    nSqz45 ./ hDARM, nSqz90 ./ hDARM, nSqz135 ./ hDARM]))
  title('Quantum Noise for Sagnac', 'fontsize', 18);
  grid on
  legend('No Squeezing', '6dB 0 dg', '6dB 45 dg', '6dB 90 dg', '6dB 135 dg')
end
