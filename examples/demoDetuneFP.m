% demoDetuneFP
%   this function demonstrates the use of tickle with optFP
%

function [f, sigDC2, sigAC2, mMech2, noiseAC2] = demoDetuneFP

  % create the model
  opt = optFP;
  
  % get some drive indexes
  nEX = getDriveIndex(opt, 'EX');
  nIX = getDriveIndex(opt, 'IX');

  % get some probe indexes
  nREFL_DC = getProbeNum(opt, 'REFL_DC');
  nREFL_I = getProbeNum(opt, 'REFL_I');
  nREFL_Q = getProbeNum(opt, 'REFL_Q');

  % compute the DC signals and TFs on resonance
  f = logspace(-1, 3, 200)';
  %f = 0.7;
  [fDC, sigDC0, sigAC0, mMech0, noiseAC0] = tickle(opt, [], f);

  
  % Print out the fields and probes, just to demonstrate these functions:
  fprintf('DC fields (fDC matrix):\n');
  showfDC(opt, fDC);
  
  fprintf('\nProbes (sigDC matrix):\n');
  showsigDC(opt, sigDC0);
  
  %fDC
  % compute the same a little off resonance
  pos = zeros(opt.Ndrive, 1);
  pos(nIX) = 0.1e-9;
  [fDC, sigDC1, sigAC1, mMech1, noiseAC1] = tickle(opt, pos, f);
  %fDC
  
  % and a lot off resonance
  pos(nIX) = 1e-9;
  [fDC, sigDC2, sigAC2, mMech2, noiseAC2] = tickle(opt, pos, f);
  %fDC
  
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
  
  %[h0(1), h1(1), h2(1)]  % HACK
  %[n0(1), n1(1), n2(1)]  % HACK
  %abs([n0(1) ./ h0(1), n1(1) ./ h1(1), n2(1) ./ h2(1)])
  
  figure(2)
  loglog(f, abs([n0 ./ h0, n1 ./ h1, n2 ./ h2]))
  title('Quantum Noise Limit for Detuned Cavity', 'fontsize', 18);
  legend('On resonance', '0.1 nm', '1 nm');
  grid on
  
  % make a response plot
%   nTRANS_DC = getProbeNum(opt, 'TRANS_DC');
%   h0 = getTF(sigAC0, nTRANS_DC, nEX);
%   h1 = getTF(sigAC1, nTRANS_DC, nEX);
%   h2 = getTF(sigAC2, nTRANS_DC, nEX);
%   
%   figure(3)
%   zplotlog(f, [h0, h1, h2])
%   title('TR Response for Detuned Cavity', 'fontsize', 18);
%   legend('On resonance', '0.1 nm', '1 nm', 'Location','SouthEast');
  
