
function opt = optTrapDual(Plaser, fDetune)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% create the model
% Create an Optickle Fabry-Perot
% Dual-wavelength optical spring
% Detune the IR with length and the green with frequency
    
%Deal with args  
if nargin < 2
    fDetune = 0;
end
    

% RF component vector - no sidebands/modulation
fMod   = 20e6; %This is not currently used
vFrf   = [0; fDetune];
lambda = 1064e-9*[1 0.5]; % Second one is green

% create model
opt = Optickle(vFrf, lambda);
 
% add a source
PIR    = 1;            % IR power
ratioP = 1/2;          % Ratio of powers
PG     = ratioP * PIR; % Green power
 
powerDistribution = [PIR PG];

opt = addSource(opt, 'Laser', sqrt(powerDistribution));

 % add an AM modulator (for intensity control, and intensity noise)
 %   opt = addModulator(opt, name, cMod)
 opt = addModulator(opt, 'AM', 1);
 opt = addLink(opt, 'Laser', 'out', 'AM', 'in', 0);

 % add an PM modulator (for frequency control and noise)
 opt = addModulator(opt, 'PM', 1i);
 opt = addLink(opt, 'AM', 'out', 'PM', 'in', 0);

 % add an RF modulator
 %   opt = addRFmodulator(opt, name, fMod, aMod)
 gamma = 0; % Keep it in but don't modulate
 opt = addRFmodulator(opt, 'Mod1', fMod, 1i * gamma);
 opt = addLink(opt, 'PM', 'out', 'Mod1', 'in', 0);

 % add mirrors
 %   opt = addMirror(opt, name, aio, Chr, Thr, Lhr, Rar, Lmd, Nmd)
 lCav = 0.9;
 T1IR = 0.0008; % T1@1064nm
 T1G  = 0.0008; % T1@532nm
 T1Vec = [T1IR T1G];
 opt  = addMirror(opt, 'IX', 0, 0, T1Vec);
 % Can we define a single transmission for ETM?
 opt  = addMirror(opt, 'EX', 0, 0.7 / lCav, 0);

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
