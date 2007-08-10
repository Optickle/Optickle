% Create an Optickle Fabry-Perot

function opt = optFP

  % RF component vector
  vMod = (-1:1)';
  fMod = 20e6;
  vFrf = fMod * vMod;
  gamma = 0.2;
  lCav = 4000;
  
  % create model
  opt = Optickle(vFrf);
  
  % add a source
  opt = addSource(opt, 'Laser', vMod == 0);

  % add an AM modulator
  opt = addModulator(opt, 'AM', 1);
  opt = addLink(opt, 'Laser', 'out', 'AM', 'in', 0);

  % add an PM modulator
  opt = addModulator(opt, 'PM', i);
  opt = addLink(opt, 'AM', 'out', 'PM', 'in', 0);

  % add an RF modulator
  opt = addRFmodulator(opt, 'Mod1', fMod, i * gamma);
  opt = addLink(opt, 'PM', 'out', 'Mod1', 'in', 1);

  % add mirrors
  opt = addMirror(opt, 'IX', 0, 0, 0.01);
  opt = addMirror(opt, 'EX', 0, 0, 0.01);

  opt = addLink(opt, 'Mod1', 'out', 'IX', 'bk', 2);
  opt = addLink(opt, 'IX', 'fr', 'EX', 'fr', lCav);
  opt = addLink(opt, 'EX', 'fr', 'IX', 'fr', lCav);
  
  % set some mechanical transfer functions
  w = 2 * pi * 0.7;   % pendulum resonance frequency
  m = 40;             % mass
  opt = setMechTF(opt, 'IX', zpk([], -w * [0.1 + 1i, 0.1 - 1i], 1 / m));
  opt = setMechTF(opt, 'EX', zpk([], -w * [0.1 + 1i, 0.1 - 1i], 1 / m));

  % add detectors
  opt = addSink(opt, 'REFL');
  opt = addSink(opt, 'TRANS');

  opt = addLink(opt, 'IX', 'bk', 'REFL', 'in', 2);
  opt = addLink(opt, 'EX', 'bk', 'TRANS', 'in', 5);

  % add probes
  phi = -83.721 * 0;
  opt = addProbeIn(opt, 'REFL_DC', 'REFL', 'in', 0, 0);		% DC
  opt = addProbeIn(opt, 'REFL_I', 'REFL', 'in', fMod, 0 + phi);	% 1f demod
  opt = addProbeIn(opt, 'REFL_Q', 'REFL', 'in', fMod, 90 + phi);% 1f demod
  opt = addProbeIn(opt, 'TRANS_DC', 'TRANS', 'in', 0, 0);	% DC
