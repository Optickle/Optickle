% demoDetuneFP
%   this function demonstrates the use of tickle with optFP
%

function demoSagnac

  % create the model
  opt = optSagnac;
  
  % get some drive indexes
  nBS = getDriveIndex(opt, 'BS');
  nCM = getDriveIndex(opt, 'CM');
  nEX = getDriveIndex(opt, 'EX');
  nEY = getDriveIndex(opt, 'IX');

  % get some probe indexes
%   nREFL_DC = getProbeNum(opt, 'REFL_DC');
%   nREFL_I = getProbeNum(opt, 'REFL_I');
%   nREFL_Q = getProbeNum(opt, 'REFL_Q');

%   nAS_DC = getProbeNum(opt, 'AS_DC');
%   nAS_I = getProbeNum(opt, 'AS_I');
%   nAS_Q = getProbeNum(opt, 'AS_Q');
  
  nRA_DC = getProbeNum(opt, 'R_HDA_DC');
  nRB_DC = getProbeNum(opt, 'R_HDB_DC');
  
  nHDA_DC = getProbeNum(opt, 'HDA_DC');
  nHDB_DC = getProbeNum(opt, 'HDB_DC');
  
  % compute the DC signals and TFs on resonance
  f = logspace(-1, 3, 200)';
  [fDC, sigDC, sigAC, ~, noiseAC] = tickle(opt, [], f);
  
  % Print out the fields and probes, just to demonstrate these functions:
  fprintf('DC fields (fDC matrix):\n');
  showfDC(opt, fDC);
  
  fprintf('\nProbes (sigDC matrix):\n');
  showsigDC(opt, sigDC);
  
  % make a response plot
%   h0 = getTF(sigAC, nRA_DC, [nBS, nPBS]);
%   h1 = getTF(sigAC, nHDA_DC, [nBS, nPBS]);
  h0 = getTF(sigAC, nRA_DC, [nEX, nEY]);
  h1 = getTF(sigAC, nHDA_DC, [nEX, nEY]);
  hREFL = h0(:, 1) - h0(:, 2);
  hDARM = h1(:, 1) - h1(:, 2);
  
  figure(1)
%   zplotlog(f, [h0, h1, hREFL, hDARM])
%   title('PDH Response to EX and EY', 'fontsize', 18);
%   legend({'EX REFL', 'EY REFL', 'EX AS', 'EY AS', 'DARM R', 'DARM AS'}, 'Location','SouthEast');
  zplotlog(f, [h0, h1])
  title('Homodyne Response to EX and EY', 'fontsize', 18);
  legend({'EX R', 'EY R', 'EX AS', 'EY AS'}, 'Location','NorthEast');
%   legend({'BS R', 'PBS R', 'BS AS', 'PBS AS'}, 'Location','NorthEast');
  
  % make a noise plot
%   n0 = noiseAC(nREFL_I, :)';
%   
%   figure(2)
%   loglog(f, abs(n0 ./ hDARM))
%   title('Quantum Noise for Sagnac', 'fontsize', 18);
%   grid on
  
end
