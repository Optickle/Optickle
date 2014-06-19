% Create an Optickle Fabry-Perot

function opt = optPolSag

  % RF component vector
  Pin = 100;
  vMod = (-1:1)';
  fMod = 20e6;
  vFrf = fMod * [vMod; vMod];  % add vMod for both polarizations
  
  lambda = 1064e-9;  % just one wavelength
  pol = [ones(size(vMod)) * Optickle.polS   % S-polarization
    ones(size(vMod)) * Optickle.polP]';     % and P-polarization
  
  % create model
  opt = Optickle(vFrf, lambda, pol);
  
  % add a source, with all power in S-pol carrier
  vArf = sqrt(Pin) * (vFrf == 0 & pol == Optickle.polS);
  opt.addSource('Laser', vArf);

  % add an AM modulator (for intensity control, and intensity noise)
  %   opt.addModulator(name, cMod)
  opt.addModulator('AM', 1);

  % add an PM modulator (for frequency control and noise)
  opt.addModulator('PM', 1i);

  % add an RF modulator
  %   opt.addRFmodulator(name, fMod, aMod)
  gamma = 0.2;
  opt.addRFmodulator('Mod1', fMod, 1i * gamma);

  % add beamsplitters mirrors
  %   opt.addBeamSplitter(name, aio, Chr, Thr, Lhr, Rar, Lmd, Nmd)
  opt.addMirror('BS', 45, 0, 0.5);  % regular beamsplitter
  
  % PBS
  PBSleakS = 0;    % leakage of S-pol power into transmission
  PBSleakP = 0;    % leakage of P-pol power into reflection
  Thr = [PBSleakS, 1064e-9, 1
         1 - PBSleakP, 1064e-9, 0];
  opt.addMirror('PBS', 45, 0, Thr);

  
  % add cavity mirrors
  %   opt.addMirror(name, aio, Chr, Thr, Lhr, Rar, Lmd, Nmd)
  lCav = 4000;
  Tin = 0.01;
  Tend = 10e-6;
  
  opt.addMirror('IX', 0, 0, Tin);
  opt.addMirror('EX', 0, 0.7 / lCav, Tend);
  opt.addMirror('IY', 0, 0, Tin);
  opt.addMirror('EY', 0, 0.7 / lCav, Tend);

  % link laser to modulators
  opt.addLink('Laser', 'out', 'AM', 'in', 0);
  opt.addLink('AM', 'out', 'PM', 'in', 0);
  opt.addLink('PM', 'out', 'Mod1', 'in', 0);
  opt.addLink('Mod1', 'out', 'BS', 'frA', 0);
  
  % beam splitters - links going forward (A sides)
  opt.addLink('BS', 'frA', 'PBS', 'frA', 0);
  opt.addLink('BS', 'bkA', 'PBS', 'bkA', 0);
  opt.addLink('PBS', 'frA', 'IY', 'bk', 0);
  opt.addLink('PBS', 'bkA', 'IX', 'bk', 0);
  
  % beam splitters - links going forward (B sides)
  opt.addLink('IY', 'bk', 'PBS', 'frB', 0);
  opt.addLink('IX', 'bk', 'PBS', 'bkB', 0);
  opt.addLink('PBS', 'frB', 'BS', 'frB', 0);
  opt.addLink('PBS', 'bkB', 'BS', 'bkB', 0);
  
  % X-arm
  opt.addLink('IX', 'fr', 'EX', 'fr', lCav);
  opt.addLink('EX', 'fr', 'IX', 'fr', lCav);
  
  % Y-arm
  opt.addLink('IY', 'fr', 'EY', 'fr', lCav);
  opt.addLink('EY', 'fr', 'IY', 'fr', lCav);
  
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Mechanical
  %%%%%%%%%%%%%%%%%%%%%%
    
  % set some mechanical transfer functions
  w = 2 * pi * 0.7;      % pendulum resonance frequency
  mI = 40;               % mass of input mirror
  mE = 40;               % mass of end mirror

  w_pit = 2 * pi * 0.5;   % pitch mode resonance frequency

  rTM = 0.17;             % test-mass radius
  tTM = 0.2;              % test-mass thickness
  iTM = (3 * rTM^2 + tTM^2) / 12;  % TM moment / mass

  iI = mE * iTM;          % moment of input mirror
  iE = mE * iTM;          % moment of end mirror

  dampRes = [0.01 + 1i, 0.01 - 1i];
  
  opt.setMechTF('IX', zpk([], -w * dampRes, 1 / mI));
  opt.setMechTF('EX', zpk([], -w * dampRes, 1 / mE));

  opt.setMechTF('IY', zpk([], -w_pit * dampRes, 1 / iI), 2);
  opt.setMechTF('EY', zpk([], -w_pit * dampRes, 1 / iE), 2);
  
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Probes
  %%%%%%%%%%%%%%%%%%%%%%
    
  % add REFL optics
  opt.addSink('REFL');
  opt.addLink('BS', 'bkB', 'REFL', 'in', 0);
  
  % add REFL probes (this call adds probes REFL_DC, I and Q)
  phi = 0;
  opt.addReadout('REFL', [fMod, phi]);

  % add unphysical intra-cavity probes
  opt.addProbeIn('EX_DC', 'EX', 'fr', 0, 0);
  opt.addProbeIn('EY_DC', 'EY', 'fr', 0, 0);  

  
  %%%%%%%%%%%%%%%%%%%%%%
  % HG Basis
  %%%%%%%%%%%%%%%%%%%%%%
    
  % tell Optickle to use this cavity basis
  opt = setCavityBasis('IX', 'EX');  
end
