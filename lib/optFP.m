% Create an Optickle Fabry-Perot

function opt = optFP

  % RF component vector
  Pin = 100;
  vMod = (-1:1)';
  fMod = 20e6;
  vFrf = fMod * vMod;
  gamma = 0.2;
  lCav = 4000;
  
  % create model
  opt = Optickle(vFrf);
  
  % add a source
  opt = addSource(opt, 'Laser', sqrt(Pin) * (vMod == 0));

  % add an AM modulator
  %   opt = addModulator(opt, name, cMod)
  opt = addModulator(opt, 'AM', 1);
  opt = addLink(opt, 'Laser', 'out', 'AM', 'in', 0);

  % add an PM modulator
  opt = addModulator(opt, 'PM', i);
  opt = addLink(opt, 'AM', 'out', 'PM', 'in', 0);

  % add an RF modulator
  %   opt = addRFmodulator(opt, name, fMod, aMod)
  opt = addRFmodulator(opt, 'Mod1', fMod, i * gamma);
  opt = addLink(opt, 'PM', 'out', 'Mod1', 'in', 1);

  % add mirrors
  %   opt = addMirror(opt, name, aio, Chr, Thr, Lhr, Rar, Lmd, Nmd)
  opt = addMirror(opt, 'IX', 0, 0, 0.01);
  opt = addMirror(opt, 'EX', 0, 0.7 / lCav, 0.001);

  opt = addLink(opt, 'Mod1', 'out', 'IX', 'bk', 2);
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

  iI = 10e10 * mE * iTM;          % moment of input mirror
  iE = 10e10 * mE * iTM;          % moment of end mirror

  dampRes = [0.01 + 1i, 0.01 - 1i];
  
  opt = setMechTF(opt, 'IX', zpk([], -w * dampRes, 1 / mI));
  opt = setMechTF(opt, 'EX', zpk([], -w * dampRes, 1 / mE));

  opt = setMechTF(opt, 'IX', zpk([], -w_pit * dampRes, 1 / iI), 2);
  opt = setMechTF(opt, 'EX', zpk([], -w_pit * dampRes, 1 / iE), 2);

  % add REFL optics
  opt = addSink(opt, 'REFL');
  opt = addLink(opt, 'IX', 'bk', 'REFL', 'in', 2);
  
  % add REFL probes
  phi = -83.721 * 0;
  opt = addProbeIn(opt, 'REFL_DC', 'REFL', 'in', 0, 0);		% DC
  opt = addProbeIn(opt, 'REFL_I', 'REFL', 'in', fMod, 0 + phi);	% 1f demod
  opt = addProbeIn(opt, 'REFL_Q', 'REFL', 'in', fMod, 90 + phi);% 1f demod

  % add TRANS optics
  opt = addTelescope(opt, 'TRANS_T1', 2, [2.2 0.19]);
  opt = addMirror(opt, 'TRANS_S1', 45, 0, 0.5);
  opt = addSink(opt, 'TRANS');
  opt = addSink(opt, 'TRANS_90');

  opt = addLink(opt, 'EX', 'bk', 'TRANS_T1', 'in', 0.3);
  opt = addLink(opt, 'TRANS_T1', 'out', 'TRANS_S1', 'fr', 0.1);
  opt = addLink(opt, 'TRANS_S1', 'fr', 'TRANS', 'in', 0.1);
  opt = addLink(opt, 'TRANS_S1', 'bk', 'TRANS_90', 'in', 4.1);

  % add TRANS probes
  opt = addProbeIn(opt, 'TRANS_DC', 'TRANS', 'in', 0, 0);	% DC
  opt = addProbeIn(opt, 'TRANS_90_DC', 'TRANS_90', 'in', 0, 0);	% DC

  % add unphysical intra-cavity probes
  opt = addProbeIn(opt, 'IX_DC', 'IX', 'fr', 0, 0);
  opt = addProbeIn(opt, 'EX_DC', 'EX', 'fr', 0, 0);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Set some modal information
  opt = setCavityBasis(opt, 'IX', 'EX');
  