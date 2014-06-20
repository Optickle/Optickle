% paramFullIFO
%   returns the parameters relevant to modeling the full IFO

function par = paramFullIFO(inputPower)

  % start with Jeff's mega parameter file
  %global cvsDir
  %addpath([ cvsDir '/LentickleAligo/ParamFiles'])

  par.inputPower = inputPower;
  par.Tsrm = 0.35;
  par.Tprm = 0.03;
  parJK = aligoifomodel_straight([], par.inputPower, par.Tsrm);

  %% some other parameters
  dETM = 10e-12; % DARM offset ~10pm is usually good
  dMICH = 0e-9;  % MICH offset (a bad idea, but 1nm ~ 10pm of DARM)
  dAsy = 30e-3;  % change from nominal 5cm asymmetry
  
  minLoss = 30e-6;  % nominal value is 37.5ppm
  
  %%%%%%%%%
  % extract things we need
  lambda = parJK.laser.lambda.r;
  
  % laser basis
  par.Laser.vFrf = parJK.modulation.allFreqs;
  par.Laser.vArf = parJK.modulation.allAmps;
  
  % modulation frequencies and depths
  par.Mod.f1 = parJK.modulation.f1.freq;
  par.Mod.g1 = parJK.modulation.f1.depth;
  
  par.Mod.f2 = parJK.modulation.f2.freq;
  par.Mod.g2 = parJK.modulation.f2.depth;
  
  % optics
  % The parameter struct must contain parameters the following
  % for each mirror: T, L, Rar, mechTF, pos, RoC, AoI

  % for simplified suspenstion TFs, use these parameters
  par.w = 2 * pi * 0.8;   % [rad/s]
  dampRes = [-0.1 + 1i, -0.1 - 1i];

  % names of optics in JK and here:
  nameJK = {'PRM','SRM', 'BS', 'ITMX', 'ITMY', 'ETMX', 'ETMY', 'PR2'};
  nameOpt = {'PR','SR', 'BS', 'IX', 'IY', 'EX', 'EY', 'PR2'};

  parCO = parJK.coreOptics;
  nameCO = {parJK.coreOptics.name};
  for n = 1:numel(nameOpt)
    m = find(strcmp(nameCO, nameJK{n}), 1);
    co = parCO(m);
    
    %%%%%%%
    % get stuff from full parameter struct
    par.(nameOpt{n}).T = co.surf1.rTrans;  % HR red transmission
    par.(nameOpt{n}).L = co.surf1.loss;    % HR reflection loss
    par.(nameOpt{n}).RoC = co.surf1.RoC;   % HR radius of curvature
    par.(nameOpt{n}).AoI = co.surf1.AoI;   % HR angle of incidence
    par.(nameOpt{n}).Rar = co.surf2.rRefl; % AR red reflection
    
    par.(nameOpt{n}).pos = co.displacement; % micro-displacement

    %%%%%%%
    % override some parameters
    
    % minimum loss is 40ppm
    if par.(nameOpt{n}).L < minLoss
      par.(nameOpt{n}).L = minLoss;
    end
    
    % start with all positions at zero
    par.(nameOpt{n}).pos = 0;
    
    % set empty mech TFs
    par.(nameOpt{n}).mass = co.mass;
    par.(nameOpt{n}).mechTF = zpk([], par.w * dampRes, 1 / co.mass);
  end
  
  % these lines are good for comparing Optickle 1 and 2
  %par.IX.mechTF = zpk([],[],0);
  %par.IY.mechTF = zpk([],[],0);
  
  par.PR.T = par.Tprm;
  
  %par.PR.T = 1;%test
  %par.SR.T = 1;%test
  
  % add a little mass asymmetry
  par.EX.mechTF = zpk([], par.w * dampRes, (1 + 0e-3) / par.EX.mass);
  
  %% Microscopic length offsets
  
  % DARM offset, for DC readout ~ 10pm
  par.EX.pos = dETM / 2;
  par.EY.pos = -dETM / 2;
  
  % MICH offset, for DC readout ~ 1nm
  par.BS.pos = -dMICH * sqrt(2);
  par.PR.pos = dMICH;
  par.SR.pos = -dMICH;
  
  % SR pos = lambda/4 for broadband signal extraction
  par.SR.pos = lambda / 4;
  
  %% OMC optics (not really)
  par.OMCa.T = 0.01;
  par.OMCa.L = 10e-6;
  par.OMCa.RoC = 2.5;
  par.OMCa.AoI = 0;
  par.OMCa.Rar = 10e-6;
  par.OMCa.pos = 0;
  par.OMCa.mechTF = [];
  
  par.OMCb = par.OMCa;
  par.Length.OMC = 1.2;  % m
  
  par.Tomc = 0.99;
  
%   % lengths (from T0900043)
%   parLen = parJK.lengths;
%   par.Length.PR_PR2 = parLen.PRMtoPR2;
%   par.Length.PR2_BS = parLen.PR2toPR3 + parLen.PR3toBS;
%   par.Length.SR = parLen.ls;
%   par.Length.IX = parLen.lx;
%   par.Length.IY = parLen.ly;
%   par.Length.EX = parLen.Lx;
%   par.Length.EY = parLen.Ly;

  % lengths (from E1101147-v2)

  par.Length.PR_PR2 = 16.6192;
  %par.Length.PR_PR2=par.Length.PR_PR2-4.5259e-04; 
        %adjusted by sheila 10/2013 to satisfy resonance conditions for sidebands
         %in PRC, SRC
  par.Length.PR2_BS = 16.1558 + 19.5384;
  par.Length.SR = 15.7409 + 15.4612 + 19.368 + 0.0953;
  par.Length.SR=par.Length.SR+ 2.4034e-04; %also adjusted by sheila 10/2013
  par.Length.IX = 0.0954 + 4.8174 + (145 + 20 + 290) / 1e3;
  par.Length.IY = 4.8628 + (145 + 20 + 290) / 1e3;
  par.Length.EX = 3994.5;
  par.Length.EY = 3994.5;
  
  % change asymmetry
  par.Length.IX = par.Length.IX + dAsy / 2;
  par.Length.IY = par.Length.IY - dAsy / 2;
  
  par.Length.avgXY = (par.Length.IX + par.Length.IY) / 2;
  par.Length.asyXY = par.Length.IX - par.Length.IY;
  par.Length.SRC = par.Length.SR + par.Length.avgXY;
  par.Length.PRC = par.Length.PR_PR2 + par.Length.PR2_BS + par.Length.avgXY;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Adjustment of demodulation phase
  % Demodulation Phases -- tuned with newSensMat.m
  % All the units are in 'degree'
  
  par.phi.phREFL1 = 1.2;          % f1 : adjusted for CARM, I-phase
  par.phi.phREFL2 = 0;
  par.phi.phREFL31 = 0;
  par.phi.phREFL32 = 0;
  
  par.phi.phAS1 = 0;
  par.phi.phAS2 = 0;
  par.phi.phAS31 = 0;
  par.phi.phAS32 = 0;
  
  par.phi.phASM = 0;
  
  par.phi.phPOP1 = -0.4;             % f1 : adjusted for PRCL, I-phase
  par.phi.phPOP2 = 0.1;            % f2 : adjusted for SRCL, I-phase
  par.phi.phPOP31 = 0;
  par.phi.phPOP32 = 0;
  
  par.phi.phPOX1 = 0;
  par.phi.phPOX2 = 0;
  par.phi.phPOX31 = 0;
  par.phi.phPOX32 = 0;
  
  par.phi.phPOY1 = 0;
  par.phi.phPOY2 = 0;
  par.phi.phPOY31 = 0;
  par.phi.phPOY32 = 0;


end
