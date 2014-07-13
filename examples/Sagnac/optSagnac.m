% Create a Sagnac Interferometer

function opt = optSagnac

  % some parameters
  lambda = 1064e-9;  % just one wavelength
  Pin = 100;
  gamma = 0.1;     % RF modulation depth
  
  Tbs  = 0.5;      % non-polarizing BS transmission
  Tin = 0.01;      % input mirror transmission
  Tend = 10e-6;    % end mirror transmission
  lCav = 4000;     % long cavity length
  
  % RF component vector
  vMod = (-1:1)';
  fMod = 20e6;
  vFrf = fMod * vMod;
  
  % squeezer parameters
  szqAng = -pi/2;
  sqzDB = 6;
  antiDB = 10;
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Optics
  %%%%%%%%%%%%%%%%%%%%%%
    
  % create model
  opt = Optickle(vFrf, lambda);
  
  % add a source, with all power in S-pol carrier
  vArf = sqrt(Pin) * (vFrf == 0);
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
  opt.addBeamSplitter('BS', 45, 0, Tbs);  % regular beamsplitter
  
  % cavity connection mirror
  opt.addBeamSplitter('CM', 45, 0, 0);

  % add cavity mirrors
  % (use beamsplitters for counter circulating modes, but cheat a little
  %  and only use 2 instead of 3).
  opt.addBeamSplitter('IX', 0, 0, Tin);
  opt.addBeamSplitter('EX', 0, 0.7 / lCav, Tend);
  opt.addBeamSplitter('IY', 0, 0, Tin);
  opt.addBeamSplitter('EY', 0, 0.7 / lCav, Tend);

  %opt.setPosOffset('BS', posPBS);
  %opt.setPosOffset('EX', -posPBS);
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Link the Optics
  %%%%%%%%%%%%%%%%%%%%%%
    
  % link laser to modulators
  opt.addLink('Laser', 'out', 'AM', 'in', 0);
  opt.addLink('AM', 'out', 'PM', 'in', 0);
  opt.addLink('PM', 'out', 'Mod1', 'in', 0);
  opt.addLink('Mod1', 'out', 'BS', 'frA', 0);
  
  % follow beam on reflection from BS
  opt.addLink('BS', 'frA', 'IY', 'bkA', 0);
  opt.addLink('IY', 'frA', 'EY', 'frA', lCav);
  opt.addLink('EY', 'frA', 'IY', 'frA', lCav);
  opt.addLink('IY', 'bkA', 'CM', 'frA', 0);
  opt.addLink('CM', 'frA', 'IX', 'bkA', 0);
  opt.addLink('IX', 'frA', 'EX', 'frA', lCav);
  opt.addLink('EX', 'frA', 'IX', 'frA', lCav);
  opt.addLink('IX', 'bkA', 'BS', 'bkB', 0);
  
  % follow beam on transmission from BS
  opt.addLink('BS', 'bkA', 'IX', 'bkB', 0);
  opt.addLink('IX', 'frB', 'EX', 'frB', lCav);
  opt.addLink('EX', 'frB', 'IX', 'frB', lCav);
  opt.addLink('IX', 'bkB', 'CM', 'frB', 0);
  opt.addLink('CM', 'frB', 'IY', 'bkB', 0);
  opt.addLink('IY', 'frB', 'EY', 'frB', lCav);
  opt.addLink('EY', 'frB', 'IY', 'frB', lCav);
  opt.addLink('IY', 'bkB', 'BS', 'frB', 0);
  
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
  % Squeezer
  %%%%%%%%%%%%%%%%%%%%%%
  
  % opt.addSqueezer(name, lambda, fRF, pol,...
  %                         sqAng, sqdB, antidB, sqzOption = 0)
  opt.addSqueezer('Sqz', lambda, 0, Optickle.polS, szqAng, sqzDB, antiDB, 0);
  opt.addLink('Sqz', 'out', 'BS', 'bkA', 0);
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Probes
  %%%%%%%%%%%%%%%%%%%%%%
    
  % add REFL optics
  opt.addSink('REFL');
  opt.addLink('BS', 'frB', 'REFL', 'in', 0);
  
  % add REFL probes (this call adds probes REFL_DC, I and Q)
  phi = 0;
  opt.addReadout('REFL', [fMod, phi]);

  % use homodyne readout at AS port
  opt.addHomodyne('HD', Optickle.c / lambda, Optickle.polS, 90, 1, 'BS', 'bkB');

end
