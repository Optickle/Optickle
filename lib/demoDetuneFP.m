% demoDetuneFP
%   this function demonstrates the use of tickle with optFP
%

function outstruct = demoDetuneFP(makePlot)

  if nargin < 1
      makePlot = 1;
  end

  % create the model
  opt = optFP;
  
  % get some drive indexes
  nEX = getDriveIndex(opt, 'EX');
  nIX = getDriveIndex(opt, 'IX');

  % get some probe indexes
  nREFL_DC = getProbeNum(opt, 'REFL_DC');
  nREFL_I = getProbeNum(opt, 'REFL_I');
  nREFL_Q = getProbeNum(opt, 'REFL_Q');

  nTRANSa_DC = getProbeNum(opt, 'TRANSa_DC');
  nTRANSb_DC = getProbeNum(opt, 'TRANSb_DC');

  % compute the DC signals and TFs on resonance
  f = logspace(-1, 3, 200)';
  [fDC0, sigDC0, sigAC0, mMech0, noiseAC0] = tickle(opt, [], f);
  
  if makePlot
      % Print out the fields and probes, just to demonstrate these functions:
      fprintf('DC fields (fDC matrix):\n');
      showfDC(opt, fDC0);
      
      fprintf('\nProbes (sigDC matrix):\n');
      showsigDC(opt, sigDC0);
  end
  
  % compute the same a little off resonance
  pos = zeros(opt.Ndrive, 1);
  pos(nEX) = 0.1e-9;
  [fDC1, sigDC1, sigAC1, mMech1, noiseAC1] = tickle(opt, pos, f);
  
  % and a lot off resonance
  pos(nEX) = 1e-9;
  [fDC2, sigDC2, sigAC2, mMech2, noiseAC2] = tickle(opt, pos, f);
  
  % make a response plot
  h0 = getTF(sigAC0, nREFL_I, nEX);
  h1 = getTF(sigAC1, nREFL_I, nEX);
  h2 = getTF(sigAC2, nREFL_I, nEX);
  
  if makePlot
      figure(1)
      zplotlog(f, [h0, h1, h2])
      title('PDH Response for Detuned Cavity', 'fontsize', 18);
      legend('On resonance', '0.1 nm', '1 nm', 'Location','SouthEast');
  end
  
  % make a noise plot
  n0 = noiseAC0(nREFL_I, :)';
  n1 = noiseAC1(nREFL_I, :)';
  n2 = noiseAC2(nREFL_I, :)';
  
  if makePlot
      figure(2)
      loglog(f, abs([n0 ./ h0, n1 ./ h1, n2 ./ h2]))
      title('Quantum Noise Limit for Detuned Cavity', 'fontsize', 18);
      legend('On resonance', '0.1 nm', '1 nm');
      grid on
  end
  
  if nargout > 0
      outstruct.fDC0 = fDC0;
      outstruct.fDC1 = fDC1;
      outstruct.fDC2 = fDC2;
      outstruct.sigDC0 = sigDC0;
      outstruct.sigDC1 = sigDC1;
      outstruct.sigDC2 = sigDC2;
      outstruct.sigAC0 = sigAC0;
      outstruct.sigAC1 = sigAC1;
      outstruct.sigAC2 = sigAC2;
      outstruct.noiseAC0 = noiseAC0;
      outstruct.noiseAC1 = noiseAC1;
      outstruct.noiseAC2 = noiseAC2;
      outstruct.mMech0 = mMech0;
      outstruct.mMech1 = mMech1;
      outstruct.mMech2 = mMech2;
  end
