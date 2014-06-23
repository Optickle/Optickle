% demoDetuneFP
%   this function demonstrates the use of tickle with optFP
%
clear all

f   = logspace(2, 4, 600)';
P   = 1;
opt = optTrap(P);

% get some drive indexes
nEX = getDriveIndex(opt, 'EX');
nIX = getDriveIndex(opt, 'IX');

% get some probe indexes
nREFL_DC = getProbeNum(opt, 'REFL_DC');
nREFL_I  = getProbeNum(opt, 'REFL_I');
nREFL_Q  = getProbeNum(opt, 'REFL_Q');

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

% and a lot off resonance
pos        = zeros(opt.Ndrive, 1);

% There is a sign inversion between Corbitt and me

% a) C = 0.5, SC = 0
cFactorA = - 0.5;
detA     = cFactorA * hwhmM;
pos(nIX) = detA;
scFactorA = 0
fDetuneA = (cFactorA-scFactorA) *hwhm
optA     = optTrap(P, fDetuneA);

[fDC, sigDC, sigAC, mMechA, noiseAC] = tickle(optA, pos, f);

f0 = 172;
Q0 = 3200;
m  = 1e-3;

laserA = getOptic(optA,'Laser');
PVec   = laserA.vArf;

PC     = PVec(2); %fix
PSC    = PVec(end); %fix

KCA  = opticalSpringK(PC,  -cFactorA,  T1, lCav, f);
KSCA = opticalSpringK(PSC, -scFactorA, T1, lCav, f);
KA   = KCA+KSCA;
tfA  = optomechanicalTF(f0, Q0, m , KA, f);


% b) C = 3, SC = 0.5
cFactorB  = - 3;
detB      = cFactorB * hwhmM;
pos(nIX)  = detB;
scFactorB = - 0.5
fDetuneB  = (cFactorB - scFactorB) * hwhm
optB      = optTrap(P, fDetuneB);

[fDC, sigDC, sigAC, mMechB, noiseAC] = tickle(optB, pos, f);

laserB = getOptic(optB,'Laser');
PVec   = laserB.vArf;

PC     = PVec(2); %fix
PSC    = PVec(end); %fix

KCB  = opticalSpringK(PC,  -cFactorB,  T1, lCav, f);
KSCB = opticalSpringK(PSC, -scFactorB, T1, lCav, f);
KB   = KCB+KSCB;
tfB  = optomechanicalTF(f0, Q0, m , KB, f);


% c) C = 3, SC = 0
cFactorC = - 3;
detC     = cFactorC * hwhmM;
pos(nIX) = detC;
scFactorC = 0;
fDetuneC = (cFactorC-scFactorC) * hwhm
optC     = optTrap(P, fDetuneC);

[fDC, sigDC, sigAC, mMechC, noiseAC] = tickle(optC, pos, f);

laserC = getOptic(optC,'Laser');
PVec   = laserC.vArf;

PC     = PVec(2); %fix
PSC    = PVec(end); %fix

KCC  = opticalSpringK(PC,  -cFactorC,  T1, lCav, f);
KSCC = opticalSpringK(PSC, -scFactorC, T1, lCav, f);
KC   = KCC+KSCC;
tfC  = optomechanicalTF(f0, Q0, m , KC, f);

% d) C = 3, SC = -0.3
cFactorD = - 3;
detD     = cFactorD * hwhmM;
pos(nIX) = detD;
scFactorD = 0.3
fDetuneD = (cFactorD-scFactorD) * hwhm
optD     = optTrap(P, fDetuneD);

[fDC, sigDC, sigAC, mMechD, noiseAC] = tickle(optD, pos, f);

laserD = getOptic(optD,'Laser');
PVec   = laserD.vArf;

PC     = PVec(2); %fix
PSC    = PVec(end); %fix

KCD  = opticalSpringK(PC,  -cFactorD,  T1, lCav, f);
KSCD = opticalSpringK(PSC, -scFactorD, T1, lCav, f);
KD   = KCD+KSCD;
tfD  = optomechanicalTF(f0, Q0, m , KD, f);



% Extract appropriate info from mMech
% (metres with rp/ metres without rp)
rpMechA = getTF(mMechA,nEX, nEX);
rpMechB = getTF(mMechB,nEX, nEX);
rpMechC = getTF(mMechC,nEX, nEX);
rpMechD = getTF(mMechD,nEX, nEX);

%Apply normal mechanical resp
% (metres without rp/ Newton)
etm          = getOptic(opt, 'EX');
pendulumResp = squeeze(freqresp(etm.mechTF, 2 * pi * f)); 

mPerNA       = pendulumResp .* rpMechA;
mPerNB       = pendulumResp .* rpMechB;
mPerNC       = pendulumResp .* rpMechC;
mPerND       = pendulumResp .* rpMechD;








figure(1)
clf
zplotlog(f, [mPerNA, mPerNB, mPerNC, mPerND])
hold all
zplotlog(f, [tfA, tfB, tfC, tfD],'--')
%title(sprintf('ETM response, detuning = %1.2f lw', det2Factor), 'fontsize', 18);
legend('a)','b)','c)','d)')%hLeg = array2legend(powerVec, 'P = ', ' W', '%3.3e');
%set(hLeg,'FontSize',12)
axis([500 1e4 1e-7 1e-3])
subplot(2,1,2)
xlim([500 1e4])


mPerN = [mPerNA, mPerNB, mPerNC, mPerND];
tf = [tfA, tfB, tfC, tfD];
figure(3)
clf
subplot(2,1,1)
loglog(f, abs(mPerN))
hold all
loglog(f, abs(tf),'--')
hold off
legend('a)','b)','c)','d)')
axis([500 1e4 1e-6 1e-3])

subplot(2,1,2)
semilogx(f, 180/pi*angle(mPerN))
hold all
semilogx(f, 180/pi*angle(tf),'--')
xlim([500 1e4])


