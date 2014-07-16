% demoPolSag
%   this function demonstrates the use of tickle with a Polarization Sagnac Interferometer
%

function demoPolSag

  % create the model
  opt = optPolSag;
  
  % get some drive indexes
  nBS = getDriveIndex(opt, 'BS');
  nPBS = getDriveIndex(opt, 'PBS');
  nEX = getDriveIndex(opt, 'EX');
  nEY = getDriveIndex(opt, 'EY');

  % get some probe indexes
  nREFL_DC = getProbeNum(opt, 'REFL_DC');
  nREFL_I = getProbeNum(opt, 'REFL_I');
  nREFL_Q = getProbeNum(opt, 'REFL_Q');

  nHDA_DC = getProbeNum(opt, 'HDA_DC');
  nHDB_DC = getProbeNum(opt, 'HDB_DC');
  
  % set output matrix for homodyne readout
  opt.mProbeOut = eye(opt.Nprobe);      % start with identity matrix
  opt.mProbeOut(nHDA_DC, nHDB_DC) = 1;  % add B to A
  opt.mProbeOut(nHDB_DC, nHDA_DC) = -1; % subtract A from B
  
  nHD = nHDB_DC;  % output nHDB_DC is now the difference
  
  % compute the DC signals and TFs on resonance
  f = logspace(-1, 3, 200)';
  [fDC, sigDC, sigAC, ~, noiseAC] = tickle(opt, [], f);
  
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
  n0 = noiseAC(nHD, :)';
  
  figure(2)
  loglog(f, abs(n0 ./ hDARM))
  title('Quantum Noise for Polarization Sagnac', 'fontsize', 18);
  grid on
  
end
