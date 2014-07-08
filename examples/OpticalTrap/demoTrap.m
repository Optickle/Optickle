% demoDetuneFP
%   this function demonstrates the use of tickle with optFP
%
clear all

power1 = 4e-2; %W

opt = optTrap(4e-2);
 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get some drive indexes
nEX = getDriveIndex(opt, 'EX');
nIX = getDriveIndex(opt, 'IX');

% get some probe indexes
nREFL_DC = getProbeNum(opt, 'REFL_DC');
nREFL_I  = getProbeNum(opt, 'REFL_I');
nREFL_Q  = getProbeNum(opt, 'REFL_Q');

% compute the DC signals and TFs on resonance
f = logspace(2, 4, 600)';
%f = 0.7;
[fDC0, sigDC0, sigAC0, mMech0, noiseAC0] = tickle(opt, [], f, Optickle.tfPos);

% Print out the fields and probes, just to demonstrate these functions:
fprintf('DC fields (fDC matrix):\n');
showfDC(opt, fDC0);

fprintf('\nProbes (sigDC matrix):\n');
showsigDC(opt, sigDC0);

% Grab cavity length
nCavLink = getLinkNum(opt, 'IX', 'EX');
vDist = getLinkLengths(opt);
lCav = vDist(nCavLink);

%Get lambda - need to be careful
par    = getOptParam(opt);
lambda = par.lambda(find(par.vFrf == 0));

%Get T1
itm   = getOptic(opt, 'IX');
T1    = itm.Thr;
fsr   = Optickle.c / (2 * lCav);

%Compute linewidth
hwhm  = 0.5 * fsr * T1 / (2 * pi) %Hz
hwhmM = (lambda / 2) * hwhm / fsr %m


% compute the same a little off resonance
pos        = zeros(opt.Ndrive, 1);
det1Factor = - 0.1;
det1       = det1Factor * hwhmM;
pos(nIX)   = det1;
[fDC1, sigDC1, sigAC1, mMech1, noiseAC1] = tickle(opt, pos, f);


% and a lot off resonance
det2Factor = - 0.5;
det2       = det2Factor * hwhmM;
pos(nIX)   = det2;
[fDC2, sigDC2, sigAC2, mMech2, noiseAC2] = tickle(opt, pos, f);
%fDC

% Extract appropriate info from mMech
% (metres with rp/ metres without rp)
rpMech0 = getTF(mMech0,nEX, nEX);
rpMech1 = getTF(mMech1,nEX, nEX);
rpMech2 = getTF(mMech2,nEX, nEX);
 
%Apply normal mechanical resp
% (metres without rp/ Newton)
etm          = getOptic(opt, 'EX');
pendulumResp = squeeze(freqresp(etm.mechTF, 2 * pi * f)); 
mPerN0       = pendulumResp .* rpMech0;
mPerN1       = pendulumResp .* rpMech1;
mPerN2       = pendulumResp .* rpMech2; 

 
figure(1)
clf
zplotlog(f, [mPerN0, mPerN1, mPerN2])
title('ETM response', 'fontsize', 18);
legend('On res', sprintf('%1.1f lw',det1Factor), sprintf(['%1.1f ' ...
                    'lw'],det2Factor), 'Location','Best');



%Perform same calculation as one would in experiment
  
% Get W/mevans
h0 = getTF(sigAC0, nREFL_I, nEX);
h1 = getTF(sigAC1, nREFL_I, nEX);
h2 = getTF(sigAC2, nREFL_I, nEX);

% Get W / N multiply by pendulum resp
h0b = h0 .* pendulumResp;
h1b = h1 .* pendulumResp;
h2b = h2 .* pendulumResp;


% Get W/m i.e. pdh calibration
opt = setMechTF(opt, 'EX', zpk([],[],0)); % Remove effects of rad
                                           % press. There are other ways
pos(nIX) = 0;
[fDC3, sigDC3, sigAC3, mMech3, noiseAC3] = tickle(opt, pos, f);
pos(nIX) = det1;
[fDC4, sigDC4, sigAC4, mMech4, noiseAC4] = tickle(opt, pos, f);
pos(nIX) = det2;
[fDC5, sigDC5, sigAC5, mMech5, noiseAC5] = tickle(opt, pos, f);

% Get W/m
h3 = getTF(sigAC3, nREFL_I, nEX);
h4 = getTF(sigAC4, nREFL_I, nEX);
h5 = getTF(sigAC5, nREFL_I, nEX);
figure(3)
clf
zplotdb(f, [h3, h4, h5])
title('PDH Response for Detuned Cavity', 'fontsize', 18);
legend('On res', sprintf(' %1.1f lw', det1Factor), sprintf('%1.1f lw', det2Factor), 'Location', 'Best');


% Apply calibration, cavity pole
h0c = h0b ./ h3;%.*rpMech0;
h1c = h1b ./ h4;%.*rpMech1;
h2c = h2b ./ h5;%.*rpMech2;


% $$$   h0 = getTF(sigAC0, nREFL_I, nEX)./rpMech0;
% $$$   h1 = getTF(sigAC1, nREFL_I, nEX)./rpMech1;
% $$$   h2 = getTF(sigAC2, nREFL_I, nEX)./rpMech2;
% $$$   h0 = getTF(sigAC0, nREFL_I, nEX);%.*pendulumResp./cavPoleResp;
% $$$   h1 = getTF(sigAC1, nREFL_I, nEX);%.*pendulumResp./cavPoleResp;
% $$$   h2 = getTF(sigAC2, nREFL_I, nEX);%.*pendulumResp./cavPoleResp;

figure(2)
clf
zplotlog(f, [h0c, h1c, h2c])
title('PDH Response for Detuned Cavity', 'fontsize', 18);
legend('On res', sprintf(' %1.1f lw', det1Factor), sprintf('%1.1f lw', det2Factor), 'Location', 'Best');


% $$$   % make a noise plot
% $$$   n0 = noiseAC0(nREFL_I, :)';
% $$$   n1 = noiseAC1(nREFL_I, :)';
% $$$   n2 = noiseAC2(nREFL_I, :)';
  
  %[h0(1), h1(1), h2(1)]  % HACK
  %[n0(1), n1(1), n2(1)]  % HACK
  %abs([n0(1) ./ h0(1), n1(1) ./ h1(1), n2(1) ./ h2(1)])
  
% $$$   figure(2)
% $$$   clf
% $$$   loglog(f, abs([n0 ./ h0, n1 ./ h1, n2 ./ h2]))
% $$$   title('Quantum Noise Limit for Detuned Cavity', 'fontsize', 18);
% $$$   legend('On resonance', '0.1 nm', '1 nm');
% $$$   grid on
  
  % make a response plot
%   nTRANS_DC = getProbeNum(opt, 'TRANS_DC');
%   h0 = getTF(sigAC0, nTRANS_DC, nEX);
%   h1 = getTF(sigAC1, nTRANS_DC, nEX);
%   h2 = getTF(sigAC2, nTRANS_DC, nEX);
%   
%   figure(3)
%   zplotlog(f, [h0, h1, h2])
%   title('TR Response for Detuned Cavity', 'fontsize', 18);
%   legend('On resonance', '0.1 nm', '1 nm', 'Location','SouthEast');
  
