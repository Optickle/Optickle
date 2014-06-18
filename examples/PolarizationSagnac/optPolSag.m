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
  Thr = 
  opt.addMirror('BS', 45, 0, 0.5);

  
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
  opt.addLink('Mod1', 'out', 'IX', 'bk', 0);
  opt.addLink('IX', 'fr', 'EX', 'fr', lCav);
  opt.addLink('EX', 'fr', 'IX', 'fr', lCav);
  
  % add unphysical intra-cavity probes
  opt.addProbeIn('IX_DC', 'IX', 'fr', 0, 0);
  opt.addProbeIn('EX_DC', 'EX', 'fr', 0, 0);
  
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
  
  opt = setMechTF('IX', zpk([], -w * dampRes, 1 / mI));
  opt = setMechTF('EX', zpk([], -w * dampRes, 1 / mE));

  opt = setMechTF('IX', zpk([], -w_pit * dampRes, 1 / iI), 2);
  opt = setMechTF('EX', zpk([], -w_pit * dampRes, 1 / iE), 2);
  
  % tell Optickle to use this cavity basis
  opt = setCavityBasis('IX', 'EX');
  
  % add REFL optics
  opt.addSink('REFL');
  opt.addLink('IX', 'bk', 'REFL', 'in', 2);
  
  % add REFL probes (this call adds probes REFL_DC, I and Q)
  phi = 0;
  opt.addReadout('REFL', [fMod, phi]);

  % add TRANS probe
  opt.addSink('TRANS');
  %opt.addLink('EX', 'bk', 'TRANS', 'in', 2);
  %opt.addProbeIn('TRANS_DC', 'TRANS', 'in', 0, 0);
  %opt.addLink('TRANS', 'out', 'EX', 'bk', 0);
  
%   % add TRANS optics (adds telescope, splitter and sinks)
%   % opt.addReadoutTelescope(name, f, df, ts, ds, da, db)
%   opt.addReadoutTelescope('TRANS', 2, [2.2 0.19], ...
%     0.5, 0.1, 0.1, 4.1);
%   opt.addLink('EX', 'bk', 'TRANS_TELE', 'in', 0.3);
%   
%   % add TRANS probes
%   opt.addProbeIn('TRANSa_DC', 'TRANSa', 'in', 0, 0);	% DC
%   opt.addProbeIn('TRANSb_DC', 'TRANSb', 'in', 0, 0);	% DC

  % add a source at the end, just for fun
%   opt.addSource('FlashLight', 0*(1e-3)^2 * (vMod == 1));
%   opt.addGouyPhase('FakeTele', pi / 4);
%   opt.addLink('FlashLight', 'out', 'FakeTele', 'in', 0.1);
%   opt.addLink('FakeTele', 'out', 'EX', 'bk', 0.1);
%   opt = setGouyPhase('FakeTele', pi / 8);
  

end
