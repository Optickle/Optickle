% Create an Optickle Fabry-Perot

function opt = optPolSag

  % some parameters
  PBSleakS = 0.01;    % leakage of S-pol power into transmission
  PBSleakP = 0.01;    % leakage of P-pol power into reflection
  
  lCav = 4000;     % long cavity length
  Tin = 0.01;      % input mirror transmission
  Tend = 10e-6;    % end mirror transmission
  
  gamma = 0.2;     % RF modulation depth
  
  % RF component vector
  Pin = 100;
  vMod = (-1:1)';
  fMod = 20e6;
  vFrf = fMod * [vMod; vMod];  % add vMod for both polarizations
  
  lambda = 1064e-9;  % just one wavelength
  pol = [ones(size(vMod)) * Optickle.polS   % S-polarization
         ones(size(vMod)) * Optickle.polP];     % and P-polarization
  
  % create model
  opt = Optickle(vFrf, lambda, pol);
  
  % add a source, with all power in S-pol carrier
  vArf = sqrt(Pin) * ((vFrf == 0) & (pol == Optickle.polP));
  opt.addSource('Laser', vArf);

  % add an AM modulator (for intensity control, and intensity noise)
  %   opt.addModulator(name, cMod)
  opt.addModulator('AM', 1);

  % add an PM modulator (for frequency control and noise)
  opt.addModulator('PM', 1i);

  % add an RF modulator
  %   opt.addRFmodulator(name, fMod, aMod)
  opt.addRFmodulator('Mod1', fMod, 1i * gamma);

  % add beamsplitters mirrors
  %   opt.addBeamSplitter(name, aio, Chr, Thr, Lhr, Rar, Lmd, Nmd)
  opt.addBeamSplitter('BS', 45, 0, 0.5);  % regular beamsplitter
  
  % PBS
  Thr = [PBSleakS, 1064e-9, 1
         1 - PBSleakP, 1064e-9, 0];
  opt.addBeamSplitter('PBS', 45, 0, Thr);

  % waveplates
  opt.addWaveplate('WPX_A', 0.25, 45);
  opt.addWaveplate('WPX_B', 0.25, -45);
  opt.addWaveplate('WPY_A', 0.25, 45);
  opt.addWaveplate('WPY_B', 0.25, -45);
  
  % add cavity mirrors
  %   opt.addMirror(name, aio, Chr, Thr, Lhr, Rar, Lmd, Nmd)
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
  opt.addLink('BS', 'frA', 'PBS', 'bkA', 0);
  opt.addLink('BS', 'bkA', 'PBS', 'bkB',  0);
  opt.addLink('PBS', 'frA', 'WPX_A', 'in', 0);
  opt.addLink('PBS', 'frB', 'WPY_A', 'in', 0);
  
  opt.addLink('WPY_A', 'out', 'IY', 'bk', 0);
  opt.addLink('WPX_A', 'out', 'IX', 'bk', 0);
  
  % X-arm
  opt.addLink('IX', 'fr', 'EX', 'fr', lCav);
  opt.addLink('EX', 'fr', 'IX', 'fr', lCav);
  
  % Y-arm
  opt.addLink('IY', 'fr', 'EY', 'fr', lCav);
  opt.addLink('EY', 'fr', 'IY', 'fr', lCav);
  
  % beam splitters - links going forward (B sides)
  opt.addLink('IY', 'bk', 'WPY_B', 'in', 0);
  opt.addLink('IX', 'bk', 'WPX_B', 'in', 0);
  
  opt.addLink('WPX_B', 'out', 'PBS', 'frB', 0);
  opt.addLink('WPY_B', 'out', 'PBS', 'frA', 0);
  opt.addLink('PBS', 'bkB', 'BS', 'frB', 0);
  opt.addLink('PBS', 'bkA', 'BS', 'bkB', 0);
  
  
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
  opt.addLink('BS', 'frB', 'REFL', 'in', 0);
  
  % add REFL probes (this call adds probes REFL_DC, I and Q)
  phi = 0;
  opt.addReadout('REFL', [fMod, phi]);

  % add AS optics
  opt.addSink('AS');
  opt.addLink('BS', 'bkB', 'AS', 'in', 0);
  
  % add AS probes (this call adds probes AS_DC, I and Q)
  phi = 0;
  opt.addReadout('AS', [fMod, phi]);

  % add unphysical intra-cavity probes
  opt.addProbeIn('EX_DC', 'EX', 'fr', 0, 0);
  opt.addProbeIn('EY_DC', 'EY', 'fr', 0, 0);  

  
  %%%%%%%%%%%%%%%%%%%%%%
  % HG Basis
  %%%%%%%%%%%%%%%%%%%%%%
    
  % tell Optickle to use this cavity basis
  opt.setCavityBasis('IX', 'EX');  
end
