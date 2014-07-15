% demoDetuneFP
%   this function demonstrates the use of tickle with optFP
%

function demoDetuneFP

  % create the model
  opt = optFP;
  
  % get some drive indexes
  nEX = opt.getDriveIndex('EX');
  nIX = opt.getDriveIndex('IX');

  % get some probe indexes
  nREFL_DC = opt.getProbeNum('REFL_DC');
  nREFL_I = opt.getProbeNum('REFL_I');
  nREFL_Q = opt.getProbeNum('REFL_Q');

  % compute the DC signals and TFs on resonance
  f = logspace(-1, 3, 200)';
  %f = 0.7;
  [fDC, sigDC0, sigAC0, mMech0, noiseAC0] = opt.tickle([], f);

  
  % Print out the fields and probes, just to demonstrate these functions:
  fprintf('DC fields (fDC matrix):\n');
  showfDC(opt, fDC);
  
  fprintf('\nProbes (sigDC matrix):\n');
  showsigDC(opt, sigDC0);
  
  % compute the same a little off resonance
  pos = zeros(opt.Ndrive, 1);
  pos(nIX) = 0.1e-9;
  [fDC, sigDC1, sigAC1, mMech1, noiseAC1] = opt.tickle(pos, f);
  
  % and a lot off resonance
  pos(nIX) = 1e-9;
  [fDC, sigDC2, sigAC2, mMech2, noiseAC2] = opt.tickle(pos, f);
  
  
  % make a response plot
  h0 = getTF(sigAC0, nREFL_I, nEX);
  h1 = getTF(sigAC1, nREFL_I, nEX);
  h2 = getTF(sigAC2, nREFL_I, nEX);
  
  figure(1)
  zplotlog(f, [h0, h1, h2])
  title('PDH Response for Detuned Cavity', 'fontsize', 18);
  legend('On resonance', '0.1 nm', '1 nm', 'Location','SouthEast');
  
  % make a noise plot
  n0 = noiseAC0(nREFL_I, :)';
  n1 = noiseAC1(nREFL_I, :)';
  n2 = noiseAC2(nREFL_I, :)';
  
  figure(2)
  loglog(f, abs([n0 ./ h0, n1 ./ h1, n2 ./ h2]))
  title('Quantum Noise Limit for Detuned Cavity', 'fontsize', 18);
  legend('On resonance', '0.1 nm', '1 nm');
  grid on
  
  % make a response plot
%   nTRANS_DC = opt.getProbeNum('TRANS_DC');
%   h0 = getTF(sigAC0, nTRANS_DC, nEX);
%   h1 = getTF(sigAC1, nTRANS_DC, nEX);
%   h2 = getTF(sigAC2, nTRANS_DC, nEX);
%   
%   figure(3)
%   zplotlog(f, [h0, h1, h2])
%   title('TR Response for Detuned Cavity', 'fontsize', 18);
%   legend('On resonance', '0.1 nm', '1 nm', 'Location','SouthEast');

end
