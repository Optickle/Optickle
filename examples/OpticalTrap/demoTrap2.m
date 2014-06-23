% demoDetuneFP
%   this function demonstrates the use of tickle with optFP
%
clear all

f        = logspace(2, 4, 600)';
nPower   = 7;
powerVec = logspace( -6, 0, nPower); %W

for ii = 1:nPower;
    P   = powerVec(ii);
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
    det2Factor = - 0.5;
    det2       = det2Factor * hwhmM;
    pos(nIX)   = det2;
    [fDC, sigDC, sigAC, mMech, noiseAC] = tickle(opt, pos, f);


    % Extract appropriate info from mMech
    % (metres with rp/ metres without rp)
    rpMech = getTF(mMech,nEX, nEX);
 
    %Apply normal mechanical resp
    % (metres without rp/ Newton)
    etm          = getOptic(opt, 'EX');
    pendulumResp = squeeze(freqresp(etm.mechTF, 2 * pi * f)); 
    mPerN(ii,:)       = pendulumResp .* rpMech;


 

    %Get some theoretical curves to check against
    f0 = 172;
    Q0 = 3200;
    m  = 1e-3;
    %    Need to account for power lost due to modulation
    tf(ii,:) = optomechanicalTF(f0, Q0, m , opticalSpringK(P, -det2Factor, T1, lCav, f), f);


end



figure(3)
clf
loglog(f, abs(mPerN))
hold all
loglog(f, abs(tf),'--')
hold off
hLeg = array2legend(powerVec, 'P = ', ' W', '%3.3e');
set(hLeg,'FontSize',12)

figure(4)
clf
semilogx(f, 180/pi*angle(mPerN))
hold all
semilogx(f, 180/pi*angle(tf),'--')
hLeg = array2legend(powerVec, 'P = ', ' W', '%3.3e');
set(hLeg,'FontSize',12)

