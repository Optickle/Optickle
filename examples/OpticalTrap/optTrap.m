% Create an Optickle Fabry-Perot

function opt = optTrap(Plaser, fDetune)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
  % create the model

%Deal with args  
  if nargin < 2
      fDetune = [];
  end
    

% RF component vector
 Pin  = Plaser;
 vMod = ( - 1:1)';
 fMod = 20e6;
 vFrf = fMod * [vMod; fDetune/fMod] 
 
 lambda = 1064e-9;   

 % create model
 opt = Optickle(vFrf, lambda);
 
 % add a source
 ratioSC = 1/5;
 if nargin > 1
     powerDistribution = (vFrf == 0) + ratioSC * (vFrf == fDetune)
 else
     powerDistribution = (vFrf == 0)
 end
 opt = addSource(opt, 'Laser', sqrt(Pin) * powerDistribution);

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
 opt = addLink(opt, 'PM', 'out', 'Mod1', 'in', 0);

 % add mirrors
 %   opt = addMirror(opt, name, aio, Chr, Thr, Lhr, Rar, Lmd, Nmd)
 lCav = 0.9;
 T1 = 0.0008;
 opt  = addMirror(opt, 'IX', 0, 0, T1);
 opt  = addMirror(opt, 'EX', 0, 0.7 / lCav, 0.00);

 opt = addLink(opt, 'Mod1', 'out', 'IX', 'bk', 0);
 opt = addLink(opt, 'IX', 'fr', 'EX', 'fr', lCav);
 opt = addLink(opt, 'EX', 'fr', 'IX', 'fr', lCav);
 
 % add unphysical intra-cavity probes
 opt = addProbeIn(opt, 'IX_DC', 'IX', 'fr', 0, 0);
 opt = addProbeIn(opt, 'EX_DC', 'EX', 'fr', 0, 0);
 
 % set some mechanical transfer functions
 w  = 2 * pi * 172; % pendulum resonance frequency
 Q  = 3200;          % pendulum Q
                     %mI = 250e-3;      % mass of input mirror
 mE = 1e-3;        % mass of end mirror
 
 
 p1    = - w / (2 * Q) * (1 - sqrt(1 - 4 * Q^2));
 p2    = - w / (2 * Q) * (1 + sqrt(1 - 4 * Q^2));

 poles = [p1, p2];
 pendulumModel = zpk([], poles, 1 / mE);


 
 %opt = setMechTF(opt, 'IX', pendulumModel);
 opt = setMechTF(opt, 'EX', pendulumModel);
 
 
 % tell Optickle to use this cavity basis
 opt = setCavityBasis(opt, 'IX', 'EX');
 
 % add REFL optics
 opt = addSink(opt, 'REFL');
 opt = addLink(opt, 'IX', 'bk', 'REFL', 'in', 2);
 
 % add REFL probes (this call adds probes REFL_DC, I and Q)
 phi = 0;
 opt = addReadout(opt, 'REFL', [fMod, phi]);


end
