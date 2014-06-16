% Create an Optickle Fabry-Perot

function opt = optFP

  % RF component vector
  Pin = 100;
  vMod = (-1:1)';
  fMod = 20e6;
  vFrf = fMod * vMod;
  
  % create model
  opt = Optickle(vFrf);
  
  % add a source
  opt = addSource(opt, 'Laser', sqrt(Pin) * (vMod == 0));

  % add an AM modulator (for intensity control, and intensity noise)
  %   opt = addModulator(opt, name, cMod)
  opt = addModulator(opt, 'AM', 1);
  opt = addLink(opt, 'Laser', 'out', 'AM', 'in', 0);

  % add an PM modulator (for frequency control and noise)
  opt = addModulator(opt, 'PM', 1i);
  opt = addLink(opt, 'AM', 'out', 'PM', 'in', 0);

  % add an RF modulator
  %   opt = addRFmodulator(opt, name, fMod, aMod)
  gamma = 0.2;
  opt = addRFmodulator(opt, 'Mod1', fMod, 1i * gamma);
  opt = addLink(opt, 'PM', 'out', 'Mod1', 'in', 1);

  % add mirrors
  %   opt = addMirror(opt, name, aio, Chr, Thr, Lhr, Rar, Lmd, Nmd)
  lCav = 4000;
  opt = addMirror(opt, 'IX', 0, 0, 0.03);
  opt = addMirror(opt, 'EX', 0, 0.7 / lCav, 0.001);

  opt = addLink(opt, 'Mod1', 'out', 'IX', 'bk', 0);
  opt = addLink(opt, 'IX', 'fr', 'EX', 'fr', lCav);
  opt = addLink(opt, 'EX', 'fr', 'IX', 'fr', lCav);
  
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
  
  %opt = setMechTF(opt, 'IX', zpk([], -w * dampRes, 1 / mI));
  opt = setMechTF(opt, 'EX', zpk([], -w * dampRes, 1 / mE));

  %opt = setMechTF(opt, 'IX', zpk([], -w_pit * dampRes, 1 / iI), 2);
  opt = setMechTF(opt, 'EX', zpk([], -w_pit * dampRes, 1 / iE), 2);
  
  % tell Optickle to use this cavity basis
  opt = setCavityBasis(opt, 'IX', 'EX');
  
  % add REFL optics
  opt = addSink(opt, 'REFL');
  opt = addLink(opt, 'IX', 'bk', 'REFL', 'in', 2);
  
  % add REFL probes (this call adds probes REFL_DC, I and Q)
  phi = 180 - 83.721;
  opt = addReadout(opt, 'REFL', [fMod, phi]);
  
  % add TRANS optics (adds telescope, splitter and sinks)
  % opt = addReadoutTelescope(opt, name, f, df, ts, ds, da, db)
  opt = addReadoutTelescope(opt, 'TRANS', 2, [2.2 0.19], ...
    0.5, 0.1, 0.1, 4.1);
  opt = addLink(opt, 'EX', 'bk', 'TRANS_TELE', 'in', 0.3);
  
  % add TRANS probes
  opt = addProbeIn(opt, 'TRANSa_DC', 'TRANSa', 'in', 0, 0);	% DC
  opt = addProbeIn(opt, 'TRANSb_DC', 'TRANSb', 'in', 0, 0);	% DC

  % add a source at the end, just for fun
  opt = addSource(opt, 'FlashLight', (1e-3)^2 * (vMod == 1));
  opt = addGouyPhase(opt, 'FakeTele', pi / 4);
  opt = addLink(opt, 'FlashLight', 'out', 'FakeTele', 'in', 0.1);
  opt = addLink(opt, 'FakeTele', 'out', 'EX', 'bk', 0.1);
  opt = setGouyPhase(opt, 'FakeTele', pi / 8);
  
  % add unphysical intra-cavity probes
  opt = addProbeIn(opt, 'IX_DC', 'IX', 'fr', 0, 0);
  opt = addProbeIn(opt, 'EX_DC', 'EX', 'fr', 0, 0);

end
