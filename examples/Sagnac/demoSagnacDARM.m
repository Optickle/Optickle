% demoSagnacDARM
%   this function demonstrates the use of tickle with a Sagnac Interferometer
%
%   this example is the same as demoSagnac, except that it uses the

function demoSagnacDARM

  % create the model (no squeezing)
  opt = optSagnac;
  
  % set the input matrix
  [opt, nDARM, nCARM] = setInDriveForDARM(opt);

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
  
  % Print out the fields and probes, just to demonstrate these functions:
  fprintf('DC fields (fDC matrix):\n');
  showfDC(opt, fDC);
  
  fprintf('\nProbes (sigDC matrix):\n');
  showsigDC(opt, sigDC);
  
  % compute the same with squeezing (squeeze angle = 0)
  opt = optSagnac(0, 6, 10);
  opt = setInDriveForDARM(opt);
  [~, ~, ~, ~, noiseSqz00] = opt.tickle([], f);
  
  % compute the same with squeezing (squeeze angle = 45)
  opt = optSagnac(pi / 4, 6, 10);
  opt = setInDriveForDARM(opt);
  [~, ~, ~, ~, noiseSqz45] = opt.tickle([], f);
  
  % compute the same with squeezing (squeeze angle = 90)
  opt = optSagnac(pi / 2, 6, 10);
  opt = setInDriveForDARM(opt);
  [~, ~, ~, ~, noiseSqz90] = opt.tickle([], f);
  
  % compute the same with squeezing (squeeze angle = 135)
  opt = optSagnac(3 * pi / 4, 6, 10);
  opt = setInDriveForDARM(opt);
  [~, ~, ~, ~, noiseSqz135] = opt.tickle([], f);
  
  % make a response plot
  hREFL = getTF(sigAC, nREFL_I, nCARM);
  hDARM = getTF(sigAC, nHD, nDARM);
  
  figure(1)
  zplotlog(f, [hREFL, hDARM])
  title('Response to CARM and DARM', 'fontsize', 18);
  legend({'CARM REFL', 'DARM AS'}, 'Location','NorthEast');
  
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


% setup the input matrix to drive CARM and DARM instead of EX and EY
%
function  [opt, nDARM, nCARM] = setInDriveForDARM(opt)
  
  % get EX and EY drive indexes
  nEX = opt.getDriveIndex('EX');
  nEY = opt.getDriveIndex('EY');
  
  % new drive indices
  nDARM = 1;
  nCARM = 2;
  
  % set the Optickle input matrix
  opt.mInDrive = zeros(opt.Ndrive, 2);  % matrix from DARM and CARM to all drives
  opt.mInDrive([nEX, nEY], nDARM) = [1, -1];     % DARM
  opt.mInDrive([nEX, nEY], nCARM) = [1, 1];      % CARM
  
end