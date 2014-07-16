% demoMultiLambda
%   this function demonstrates the use of multiple wavelengths
%
% Note: This is an "all in one file" demo, which is not usually
% the best structure, but it shows all of the steps together.

function demoMultiLambda

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Build Optickle Model
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % RF component vector
  Pin = 1;
  vMod = (-1:1)';
  fMod = 20e6;
  vFrf = fMod * vMod;
  
  lambda = 1064e-9 * ones(size(vFrf));
  
  % add second carrier at 532nm
  vFrf = [vFrf; 0];
  lambda = [lambda; 532e-9];
  
  nRed = 2;  % index of 1064nm carrier field in fDC
  nGrn = 4;  % index of 532nm carrier field in fDC
  
  % create model
  opt = Optickle(vFrf,lambda);
  
  % add a source, with power in red and green carriers
  opt.addSource('Laser', sqrt(Pin) * (vFrf==0));

  % add an RF modulator
  %   opt.addRFmodulator(name, fMod, aMod)
  gamma = 1.2;
  opt.addRFmodulator('Mod1', fMod, 1i * gamma);
  opt.addLink('Laser', 'out', 'Mod1', 'in', 0);

  % add mirrors
  %   opt.addMirror(name, aio, Chr, Thr, Lhr, Rar, Lmd, Nmd)
  lCav = 4000;
  opt.addMirror('IX', 0, 0, [0.3 1064e-9; 0.1 532e-9]);
  opt.addMirror('EX', 0, 0.7 / lCav, 0.001);

  opt.addLink('Mod1', 'out', 'IX', 'bk', 0);
  
  % here we add the green phase offset
  phaseOffsetGreen = [0 1064e-9
                      pi/10  532e-9];
  
  opt.addLink('IX', 'fr', 'EX', 'fr', lCav, phaseOffsetGreen);
  opt.addLink('EX', 'fr', 'IX', 'fr', lCav, phaseOffsetGreen);
  
  % add REFL optics
  opt.addSink('REFL');
  opt.addLink('IX', 'bk', 'REFL', 'in', 0);
  
  % add REFL probes (this call adds probes REFL_DC, I and Q)
  phi = 0;
  opt.addReadout('REFL', [fMod, phi]);
    
  % add unphysical intra-cavity probes
  opt.addProbeIn('IX_DC', 'IX', 'fr', 0, 0);
  opt.addProbeIn('EX_DC', 'EX', 'fr', 0, 0);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Show DC Fields and Signals
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  [fDC,sigDC] = tickle(opt);
  showfDC(opt,fDC)
  showsigDC(opt,sigDC)
  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Plot Intra-cavity Powers vs. EX position
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  nEX = opt.getDriveNum('EX');       % EX position drive
  nDC = opt.getProbeNum('EX_DC');    % DC probe on EX
  nFld = opt.getFieldIn('EX', 'fr'); % field incident on EX
  
  % make a linear sweep of EX
  lenSweep = linspace(-0.1, 0.6, 1000);
  posSweep = zeros(opt.Ndrive,length(lenSweep));
  posSweep(nEX,:)=lenSweep*1e-6;
  [fDcSweep,sigDcSweep] = sweep(opt,posSweep);
  
  % plot DC signal, and carrier powers
  figure(1)  
  plot(lenSweep,sigDcSweep(nDC,:),'k',...
       lenSweep,abs(squeeze(fDcSweep(nFld,nRed,:))).^2,'r',...
       lenSweep,abs(squeeze(fDcSweep(nFld,nGrn,:))).^2,'g');
   xlim(lenSweep([1, end]))
   grid on
   set(get(gca,'Children'),'Linewidth',5)
   xlabel('Position [um]')
   ylabel('Power [W]')
   legend('DC Signal', '1064nm Carrier', '532nm Carrier')
   
end