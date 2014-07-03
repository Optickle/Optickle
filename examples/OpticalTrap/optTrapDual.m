
function [opt, f0, Q0, m] = optTrapDual(Plaser, fDetune, T1IR, T1G)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% create the model
% Create an Optickle Fabry-Perot
% Dual-wavelength optical spring
% Detune the IR with length and the green with frequency
    
%Deal with args  
if nargin < 1
    Plaser = 1;
end

if nargin < 2
    fDetune = 0;
end

if nargin < 4
    T1IR = 0.0008; % T1@1064nm
    T1G  = 0.85*0.0008; % T1@532nm
end
    

% RF component vector - no sidebands/modulation
fMod = 20e6; % Not actually used in a meaningful way
vFrf   = [0; fDetune];
lambda = 1064e-9*[1 0.5]; % Second one is green

% create model
opt = Optickle(vFrf, lambda);
 
% add a source
PIR    = 1;            % IR power
ratioP = 1;            % Ratio of powers
PG     = ratioP * PIR; % Green power
 
powerDistribution = [PIR PG];

opt = addSource(opt, 'Laser', sqrt(powerDistribution));


 % add mirrors
 %   opt = addMirror(opt, name, aio, Chr, Thr, Lhr, Rar, Lmd, Nmd)
 lCav = 0.9;
 
 T1Vec = [T1IR T1G];
 
 %Transmissivity values should go [T lambda; T lambda]
 T1 = [T1Vec' lambda'];

 opt  = addMirror(opt, 'IX', 0, 0,T1);
 % Can we define a single transmission for ETM?
 opt  = addMirror(opt, 'EX', 0, 0.7 / lCav, 0);

 opt = addLink(opt, 'Laser', 'out', 'IX', 'bk', 0);
 opt = addLink(opt, 'IX', 'fr', 'EX', 'fr', lCav);
 opt = addLink(opt, 'EX', 'fr', 'IX', 'fr', lCav);
 
 % set some mechanical transfer functions
 f0 = 172;
 w  = 2 * pi * f0; % pendulum resonance frequency
 Q0  = 3200;          % pendulum Q
                     %mI = 250e-3;      % mass of input mirror
 m = 1e-3;        % mass of end mirror
 
 
 p1    = - w / (2 * Q0) * (1 - sqrt(1 - 4 * Q0^2));
 p2    = - w / (2 * Q0) * (1 + sqrt(1 - 4 * Q0^2));

 poles = [p1, p2];
 pendulumModel = zpk([], poles, 1 / m);


 
 
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
