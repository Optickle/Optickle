function par = aligoifomodel_straight(cvsDir,inputPower,srmTrans)
% par = aligoifomodel_straight(cvsDir,inputPower,srmTrans)
%
% ALIGOIFOMODEL_STRAIGHT returns the parameters ("par") of an aLIGO
% straight, un-folded interferometer (i.e. H1 or L1).
%
% Based on paramPowerL1 from L. Barsotti's Pickle work, with information
% filled in from a bunch of other references.
% J. Kissel, Dec 1 2010
%
% Table of Contents:
% 1 ...... Physical Constants
% 2 ...... Laser Parameters
% 3 ...... Modulation Pararmaters
% 4 ...... Input Optics
% 5 ...... Core Optics
% 6 ...... Output Optics
% 7 ...... OMC Optics
% 8 ...... Aux/Other Optics
% 9 ...... Detector Geometry
% 10 ..... Seismic Isolation
%
% Example: (aLIGO, mode 1a)
% inputPower = 25;    % W
% srmTrans = 0.20;    % [] in power
% cvsDir = '/ligo/svncommon/IscCVS/iscmodeling/'; % where the isc repo is
%                                                 % checked out on your
%                                                 % computer  
% par = aligoifomodel_straight(cvsDir,inputPower,srmTrans)
% par = 
%       constants: [1x1 struct]
%           laser: [1x1 struct]
%      modulation: [1x1 struct]
%        inOptics: [1x8 struct]
%      coreOptics: [1x15 struct]
%       outOptics: [1x4 struct]
%       omcOptics: [1x6 struct]
%         lengths: [1x1 struct]
%       seiIsoTFs: [1x1 struct]
%     optoMechTFs: [1x1 struct]
% >>
%
% References:
% [1] S. Signh, R.G. Smith, L. G. Van Uitert. "Stimulated-emission cross
%     section and fluorescent quantum efficiency of Nd3+ in yttrium aluminum
%     garnet at room temperature" Phys. Rev. B 10, 2566–2572 (1974)   
%     <http://prb.aps.org/abstract/PRB/v10/i6/p2566_1>
% [2] R. Abbot, et al. "Advanced LIGO Length Sensing and Control Final
%     Design." LIGO Internal Document. LIGO-T1000298 (2010)
% [3] M. Arain and G. Mueller. "Optical Layout and Parameters for the
%     Advanced LIGO Cavities." Ligo Internal Document. LIGO-T0900043 (2009) 
% [4] H. Armandula, G. Billingsley, G. Harry, W. Kells. "Core Optics Components
%     Final Design." LIGO Internal Document. LIGO-E080494
% [5] ISC Team. "IFOModel.m" Part of the GWINC Software Package. 
%     <http://ilog.ligo-wa.caltech.edu:7285/advligo/GWINC>
% [6] COC Team. "As Built Data [for LIGO Core Optics]." Unpublished
%     Webpage. <https://nebula.ligo.caltech.edu/optics/>
% [7] S. Waldman "Output Mode Cleaner Design." LIGO Internal Document.
%     LIGO-T1000276 (2010)
% [8] K. Kawabe "Mode Matching Telescope for the Advanced LIGO Output Mode
%     Cleaners." LIGO Internal Document. LIGO-T1000317 (2010)
%
% Glossary:
% RoC - Radius of Curvature
% AoI - Angle of Incidence
% HR - high[,ly]-reflect[ive,or,ing]
% AR - anti-reflect[ive,ing,or]
% rTrans - Transmission (in power) of "red" 1064 nm light
% gTrans - Transmission (in power) of "green" 532 nm light
%
% Notes:
% ALL POSITIONS ARE AT THE CENTER OF THE HR SURFACE OF OPTIC, except for
% CPs and ERMs, which are from the center of ESD surface (which is closest
% to the test mass).
%
% Written using the examples of Lisa Barsotti and Nic Smith's code for her
% aLIGO ASC Modelling and his eLIGO LSC/ASC modeling, respectively. 
% 
% Original Version written by Jeff Kissel, Winter 2010/2011.
%
% $Id: aligoifomodel_straight.m,v 1.12 2012/04/11 17:29:47 mevans Exp $


%% 1 %% Physical Constants %% %%
%%%|Property       | Value            | Units (notes)  | Reference    %%%%%
par.constants.n_V  = 1.00000;         % []             
par.constants.n_FS = 1.44963;         % []
par.constants.c    = 299792458;       % m s^{-1}
par.constants.e    = 1.6021765e-19;   % C

%% 2 %% Laser %% %%
%%%|Property            | Value          | Units (notes)                   | Reference    %%%%%
par.laser.inputPower    = inputPower;    % W                               [User Input, Nominal Mode 1b is 125]
par.laser.lambda.r      = 1064e-9;       % nm                              [1]
par.laser.lambda.g      = 532e-9;        % nm                              [Calc'd, lambda.r/2 ]

%% 3 %% Modulation %% %%
%%%|Property            | Value          | Units (notes)                   | Reference    %%%%%
par.modulation.f1.freq   = 9.099471e6;    % Hz                             [2]
par.modulation.f1.nHarms = 3;             % [] (number of harmonics)       [2]
par.modulation.f1.depth  = 0.1;           % [] (modulation depth)          [Lisa's Pickle Model (paramNewMIX.m)]
par.modulation.f2.freq   = 45.497355e6;   % Hz                             [2]
par.modulation.f2.nHarms = 3;             % []                             [2]
par.modulation.f2.depth  = 0.1;           % [] (number of harmonics)       [Lisa's Pickle Model (paramNewMIX.m)]

% Build modulation frequency vector for analysis
par.modulation.fp.freq  = par.modulation.f1.freq + par.modulation.f2.freq; 
par.modulation.fm.freq  = par.modulation.f1.freq - par.modulation.f2.freq;
par.modulation.allFreqs = unique([(-par.modulation.f1.nHarms:par.modulation.f1.nHarms)' * par.modulation.f1.freq;...
                                  (-par.modulation.f2.nHarms:par.modulation.f2.nHarms)' * par.modulation.f2.freq;...
                                    par.modulation.fp.freq; -par.modulation.fp.freq; ...
                                    par.modulation.fm.freq; -par.modulation.fm.freq]);

% Build modulation amplitude vector, with all input power in the carrier                         
par.modulation.carrierInd = find(par.modulation.allFreqs == 0, 1);
par.modulation.allAmps    = zeros(size(par.modulation.allFreqs));
par.modulation.allAmps(par.modulation.carrierInd) = sqrt(par.laser.inputPower);                    

%% 4 %% Input Optics %% %%
%%%%%          | Property     | Value        | Units (notes)                    |Reference   %%%%%
par.inOptics(1).name          = 'MC1';
par.inOptics(1).location      = 'HAM2';
par.inOptics(1).susType       = 'hststrpl';   % [] (HAM Small Triple)
par.inOptics(1).seiType       = 'hamprcl';    % [] (HAM ISI [No FF L4Cs] + HAM HEPI)
par.inOptics(1).surf1.AoI     = 44.59;        % deg                        [E070085]
par.inOptics(1).surf1.RoC     = inf;          % m (just fine.)             [T0900386]
par.inOptics(1).surf1.plrztn  = 'S';          % [] (S-Polarized)           [E070085]
par.inOptics(1).surf1.rTrans  = 6000e-6;      % [] (in power, @ 1064 nm)   [E070085]
par.inOptics(1).surf1.gTrans  = NaN;          % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.inOptics(1).surf1.loss    = 1e-6;         % [] (in power, @ 1064 nm)   [E070085]
par.inOptics(1).surf2.AoI     = 43.70;        % deg                        [E070085]
par.inOptics(1).surf2.RoC     = inf;          % m (just fine.)             [T0900386]
par.inOptics(1).surf2.plrztn  = 'S';          % [] (S-Polarized)           [E070085]
par.inOptics(1).surf2.rRefl   = 300e-6;       % [] (in power, @ 1064 nm)   [E070085]
par.inOptics(1).surf2.gRefl   = NaN;          % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.inOptics(1).surf2.loss    = 3e-6;         % [] (in power, @ 1064 nm)   [E070085]
par.inOptics(1).substrateLoss = 2e-7;         % [] (in power, @ 1064 nm)   [Upper Limit, P. Fritschel]
par.inOptics(1).wedgeAngle    = 0.5;          % deg                        [D070091]
par.inOptics(1).wedgeOrient   = '+X-Y';       % [] (Thick +X, -Y)          [D070091]
par.inOptics(1).diameter      = 0.150;        % m                          [D070091]
par.inOptics(1).thickness     = 0.075;        % m (at max)                 [D070091]
par.inOptics(1).mass          = 2.92;         % kg                         [Calc'd, using 2.2e3 kg m^(-3) for Fused Silica]
par.inOptics(1).displacement  = 0.000;        % m (for starters.)
par.inOptics(1).position      = [ -20.072;... % m (X)                      [D0901920]
                                    0.255;... % m (Y)                    
                                   -0.098];   % m (Z)
                                
par.inOptics(2).name          = 'MC2';
par.inOptics(2).location      = 'HAM3';
par.inOptics(2).susType       = 'hststrpl';   % [] (HAM Small Triple)
par.inOptics(2).seiType       = 'hamprcl';    % [] (HAM ISI [No FF L4Cs] + HAM HEPI)
par.inOptics(2).surf1.AoI     = 0.82;         % deg                        [E070086]
par.inOptics(2).surf1.RoC     = 27.240;       % m                          [E070079]
par.inOptics(2).surf1.plrztn  = 'S';          % [] (S-Polarized)           [E070086]
par.inOptics(2).surf1.rTrans  = 10e-6;        % [] (in power, @ 1064 nm)   [E070086]
par.inOptics(2).surf1.gTrans  = NaN;          % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.inOptics(2).surf1.loss    = 1e-6;         % [] (in power, @ 1064 nm)   [E070086]
par.inOptics(2).surf2.AoI     = 0.10;         % deg                        [E070086]
par.inOptics(2).surf2.RoC     = inf;          % m                          [E070079]
par.inOptics(2).surf2.plrztn  = 'S';          % [] (S-Polarized)           [E070086]
par.inOptics(2).surf2.rRefl   = 300e-6;       % [] (in power, @ 1064 nm)   [E070086]
par.inOptics(2).surf2.gRefl   = NaN;          % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.inOptics(2).surf2.loss    = 3e-6;         % [] (in power, @ 1064 nm)   [E070086]
par.inOptics(2).substrateLoss = 2e-7;         % [] (in power, @ 1064 nm)   [Upper Limit, P. Fritschel]
par.inOptics(2).wedgeAngle    = 0.5;          % deg                        [D070092]
par.inOptics(2).wedgeOrient   = '+Y';         % [] (Thick +X)              [D070092]
par.inOptics(2).diameter      = 0.150;        % m                          [D070092]
par.inOptics(2).thickness     = 0.075;        % m (at max)                 [D070092]
par.inOptics(2).mass          = 2.92;         % kg                         [Calc'd, using 2.2e3 kg m^(-3) for Fused Silica]
par.inOptics(2).displacement  = 0.000;        % m (for starters.)
par.inOptics(2).position      = [  -3.883;... % m (X)                      [D0901920]
                                    0.488;... % m (Y)                    
                                   -0.088];   % m (Z)
                                
par.inOptics(3).name          = 'MC3';
par.inOptics(3).location      = 'HAM2';
par.inOptics(3).susType       = 'hststrpl';   % [] (HAM Small Triple)
par.inOptics(3).seiType       = 'hamprcl';    % [] (HAM ISI [No FF L4Cs] + HAM HEPI)
par.inOptics(3).surf1.AoI     = 44.59;        % deg                        [E070078]
par.inOptics(3).surf1.RoC     = inf;          % m (just fine.)             [T0900386]
par.inOptics(3).surf1.plrztn  = 'S';          % [] (S-Polarized)           [E070078]
par.inOptics(3).surf1.rTrans  = 6000e-6;      % [] (in power, @ 1064 nm)   [E070078]
par.inOptics(3).surf1.gTrans  = NaN;          % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.inOptics(3).surf1.loss    = 1e-6;         % [] (in power, @ 1064 nm)   [E070078]
par.inOptics(3).surf2.AoI     = 43.70;        % deg                        [E070078]
par.inOptics(3).surf2.RoC     = inf;          % m                          [T0900386]
par.inOptics(3).surf2.plrztn  = 'S';          % [] (S-Polarized)           [E070078]
par.inOptics(3).surf2.rRefl   = 300e-6;       % [] (in power, @ 1064 nm)   [E070078]
par.inOptics(3).surf2.gRefl   = NaN;          % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.inOptics(3).surf2.loss    = 1e-6;         % [] (in power, @ 1064 nm)   [E070078]
par.inOptics(3).substrateLoss = 2e-7;         % [] (in power, @ 1064 nm)   [Upper Limit, P. Fritschel]
par.inOptics(3).wedgeAngle    = 0.5;          % deg                        [D070093]
par.inOptics(3).wedgeOrient   = '+X+Y';       % [] (Thick +X, +Y)          [D070093]
par.inOptics(3).diameter      = 0.150;        % m                          [D070093]
par.inOptics(3).thickness     = 0.075;        % m (at max)                 [D070093]
par.inOptics(3).mass          = 2.92;         % kg                         [Calc'd, using 2.2e3 kg m^(-3) for Fused Silica]
par.inOptics(3).displacement  = 0.000;        % m (for starters.)
par.inOptics(3).position      = [ -20.072;... % m (X)                      [D0901920]
                                    0.720;... % m (Y)                    
                                   -0.098];   % m (Z)

par.inOptics(4).name          = 'SM1';
par.inOptics(4).location      = 'HAM2';
par.inOptics(4).susType       = 'hauxsngl';   % [] (HAM AUX Small Optic Single)
par.inOptics(4).seiType       = 'hamprcl';    % [] (HAM ISI [No FF L4Cs] + HAM HEPI) 
par.inOptics(4).surf1.AoI     = 53.19;        % deg                        [E070091]
par.inOptics(4).surf1.RoC     = inf;          % m                          [T0900386]
par.inOptics(4).surf1.plrztn  = 'S';          % [] (S-Polarized)           [E070091]
par.inOptics(4).surf1.rTrans  = 500e-6;       % [] (in power, @ 1064 nm)   [E070091]
par.inOptics(4).surf1.gTrans  = NaN;          % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.inOptics(4).surf1.loss    = 3e-6;         % [] (in power, @ 1064 nm)   [E070091]
par.inOptics(4).surf2.AoI     = 54.21;        % deg                        [E070091]
par.inOptics(4).surf2.RoC     = inf;          % m                          [T0900386]
par.inOptics(4).surf2.plrztn  = 'S';          % [] (S-Polarized)           [E070091]
par.inOptics(4).surf2.rRefl   = 300e-6;       % [] (in power, @ 1064 nm)   [E070091]
par.inOptics(4).surf2.gRefl   = NaN;          % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.inOptics(4).surf2.loss    = 3e-6;         % [] (in power, @ 1064 nm)   [E070091]
par.inOptics(4).substrateLoss = 2e-7;         % [] (in power, @ 1064 nm)   [Upper Limit, P. Fritschel]
par.inOptics(4).wedgeAngle    = 0.5;          % deg                        [D070097]
par.inOptics(4).wedgeOrient   = '-X-Y';       % [] (Thick -X,-Y)           [D070097]
par.inOptics(4).diameter      = 0.075;        % m                          [D070097]
par.inOptics(4).thickness     = 0.025;        % m (at max)                 [D070097]
par.inOptics(4).mass          = 0.243;        % kg                         [Calc'd, using 2.2e3 kg m^(-3) for Fused Silica]
par.inOptics(4).displacement  = 0.000;        % m (for starters.)
par.inOptics(4).position      = [ -20.581;... % m (X)                      [D0901920]
                                    0.748;... % m (Y)                    
                                   -0.098];   % m (Z)  
                               
par.inOptics(5).name          = 'PMMT1';
par.inOptics(5).location      = 'HAM2';
par.inOptics(5).susType       = 'hauxsngl';   % [] (Small Optic Single)
par.inOptics(5).seiType       = 'hamprcl';    % [] (HAM ISI [No FF L4Cs] + HAM HEPI)
par.inOptics(5).surf1.AoI     = 7.01;         % deg                        [E080137]
par.inOptics(5).surf1.RoC     = 12.8;         % m                          [E080135] 
par.inOptics(5).surf1.plrztn  = 'P';          % []                         [E080137]
par.inOptics(5).surf1.rTrans  = 50e-6;        % [] (in power, @ 1064 nm)   [E080137]
par.inOptics(5).surf1.gTrans  = NaN;          % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.inOptics(5).surf1.loss    = 3e-6;         % [] (in power, @ 1064 nm)   [E080137]
par.inOptics(5).surf2.AoI     = 7.74;         % deg                        [E080137] 
par.inOptics(5).surf2.RoC     = inf;          % m                          [E080135]
par.inOptics(5).surf2.plrztn  = 'P';          % []                         [E080137]
par.inOptics(5).surf2.rRefl   = 300e-6;       % [] (in power, @ 1064 nm)   [E080137]
par.inOptics(5).surf2.gRefl   = NaN;          % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.inOptics(5).surf2.loss    = 3e-6;         % [] (in power, @ 1064 nm)   [E080137]
par.inOptics(5).substrateLoss = 2e-7;         % [] (in power, @ 1064 nm)   [Upper Limit, P. Fritschel]
par.inOptics(5).wedgeAngle    = 0.5;          % deg                        [D080160]
par.inOptics(5).wedgeOrient   = '-X+Y';       % [] (Thick +X,-Y)           [D080160]
par.inOptics(5).diameter      = 0.075;        % m                          [D080160]
par.inOptics(5).thickness     = 0.025;        % m (at max)                 [D080160]
par.inOptics(5).mass          = 0.243;        % kg                         [Calc'd, using 2.2e3 kg m^(-3) for Fused Silica]
par.inOptics(5).displacement  = 0.000;        % m (for starters.)
par.inOptics(5).position      = [ -20.978;... % m (X)                      [D0901920]
                                   -0.479;... % m (Y)                    
                                   -0.098];   % m (Z)
     
par.inOptics(6).name          = 'IFI';
par.inOptics(6).location      = 'HAM2';
par.inOptics(6).susType       = 'none';      % [] (Yikes!)
par.inOptics(6).seiType       = 'hamprcl';   % [] (HAM ISI [No FF L4Cs] + HAM HEPI)
par.inOptics(6).surf1.AoI     = 0;            % deg                        []
par.inOptics(6).surf1.RoC     = 0;            % m                          []
par.inOptics(6).surf1.plrztn  = '';           % []                         []
par.inOptics(6).surf1.rTrans  = 0;            % [] (in power, @ 1064 nm)   []
par.inOptics(6).surf1.gTrans  = NaN;          % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.inOptics(6).surf1.loss    = 0;            % [] (in power, @ 1064 nm)   []
par.inOptics(6).surf2.AoI     = 0;            % deg                        []
par.inOptics(6).surf2.RoC     = 0;            % m                          []
par.inOptics(6).surf2.plrztn  = '';           % []                         []
par.inOptics(6).surf2.rRefl   = 0;            % [] (in power, @ 1064 nm)   []
par.inOptics(6).surf2.gRefl   = NaN;          % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.inOptics(6).surf2.loss    = 0;            % [] (in power, @ 1064 nm)   []
par.inOptics(6).substrateLoss = 0;            % [] (in power, @ 1064 nm)   []
par.inOptics(6).wedgeAngle    = 0;            % deg                        []
par.inOptics(6).wedgeOrient   = '';           % [] (Thick)                 []
par.inOptics(6).diameter      = 0;            % m                          []
par.inOptics(6).thickness     = 0;            % m (at max)                 []
par.inOptics(6).mass          = 0;            % kg                         []
par.inOptics(6).displacement  = 0.000;        % m (for starters.)
par.inOptics(6).position      = [ -20.640;... % m (X)  (At input)          [D0901920]
                                    0.015;... % m (Y)       |             
                                   -0.098];   % m (Z)       v
                               
par.inOptics(7).name          = 'PMMT2';
par.inOptics(7).location      = 'HAM2';
par.inOptics(7).susType       = 'hauxsngl';   % [] (Small Optic Single)
par.inOptics(7).seiType       = 'hamprcl';    % [] (HAM ISI [No FF L4Cs] + HAM HEPI)
par.inOptics(7).surf1.AoI     = 7.08;         % deg                        [E080138]
par.inOptics(7).surf1.RoC     = -6.24;        % m                          [E080136]
par.inOptics(7).surf1.plrztn  = 'P';          % []                         [E080138]
par.inOptics(7).surf1.rTrans  = 50e-6;        % [] (in power, @ 1064 nm)   [E080138]
par.inOptics(7).surf1.gTrans  = NaN;          % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.inOptics(7).surf1.loss    = 3e-6;         % [] (in power, @ 1064 nm)   [E080138]
par.inOptics(7).surf2.AoI     = 7.81;         % deg                        [E080138]
par.inOptics(7).surf2.RoC     = inf;          % m                          [E080136]
par.inOptics(7).surf2.plrztn  = 'P';          % []                         [E080138]
par.inOptics(7).surf2.rRefl   = 300e-6;       % [] (in power, @ 1064 nm)   [E080138]
par.inOptics(7).surf2.gRefl   = NaN;          % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.inOptics(7).surf2.loss    = 3e-6;         % [] (in power, @ 1064 nm)   [E080138]
par.inOptics(7).substrateLoss = 2e-7;         % [] (in power, @ 1064 nm)   [Upper Limit, P. Fritschel]
par.inOptics(7).wedgeAngle    = 0.5;          % deg                        [D080161]
par.inOptics(7).wedgeOrient   = '-X+Y';       % [] (Thick -X,+Y)           [D080161]
par.inOptics(7).diameter      = 0.075;        % m                          [D080161]
par.inOptics(7).thickness     = 0.025;        % m (at max)                 [D080161]
par.inOptics(7).mass          = 0.243;        % kg                         [Calc'd, using 2.2e3 kg m^(-3) for Fused Silica]
par.inOptics(7).displacement  = 0.000;        % m (for starters.)
par.inOptics(7).position      = [ -20.318;... % m (X)                      [D0901920]
                                    0.486;... % m (Y)                    
                                   -0.098];   % m (Z)
                                
par.inOptics(8).name          = 'SM2';
par.inOptics(8).location      = 'HAM2';
par.inOptics(8).susType       = 'hauxsngl';   % [] (Small Optic Single)
par.inOptics(8).seiType       = 'hamprcl';    % [] (HAM ISI [No FF L4Cs] + HAM HEPI) 
par.inOptics(8).surf1.AoI     = 35.89;        % deg                        [E070092]
par.inOptics(8).surf1.RoC     = inf;          % m (just fine.)             [T0900386]
par.inOptics(8).surf1.plrztn  = 'P';          % [] (P-Polarized)           [E070092]
par.inOptics(8).surf1.rTrans  = 2400e-6;      % [] (in power, @ 1064 nm)   [E070092]
par.inOptics(8).surf1.gTrans  = NaN;          % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.inOptics(8).surf1.loss    = 3e-6;         % [] (in power, @ 1064 nm)   [E070092]
par.inOptics(8).surf2.AoI     = 36.71;        % deg                        [E070092]
par.inOptics(8).surf2.RoC     = inf;          % m                          [T0900386]
par.inOptics(8).surf2.plrztn  = 'P';          % [] (P-Polarized)           [E070092]
par.inOptics(8).surf2.rRefl   = 300e-6;       % [] (in power, @ 1064 nm)   [E070092]
par.inOptics(8).surf2.gRefl   = NaN;          % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.inOptics(8).surf2.loss    = 3e-6;         % [] (in power, @ 1064 nm)   [E070092]
par.inOptics(8).substrateLoss = 2e-7;         % [] (in power, @ 1064 nm)   [Upper Limit, P. Fritschel]
par.inOptics(8).wedgeAngle    = 0.5;          % deg                        [D070097]
par.inOptics(8).wedgeOrient   = '+X-Y';       % [] (Thick +X,-Y)           [D070097]
par.inOptics(8).diameter      = 0.075;        % m                          [D070097]
par.inOptics(8).thickness     = 0.025;        % m (at max)                 [D070097]
par.inOptics(8).mass          = 0.243;        % kg                         [Calc'd, using 2.2e3 kg m^(-3) for Fused Silica]
par.inOptics(8).displacement  = 0.000;        % m (for starters.)
par.inOptics(8).position      = [ -20.678;... % m (X)                      [D0901920]
                                   -0.657;... % m (Y)                    
                                   -0.098];   % m (Z)

%% 5 %% Core Optics %% %%            
%%%%% Power Recycling Cavity                                                             %%%%%
%%%%%            |Property      | Value        | Units (notes)            | Reference    %%%%%  
% Power Recycling Mirror (PRM)
par.coreOptics(1).name          = 'PRM';
par.coreOptics(1).location      = 'HAM2';
par.coreOptics(1).susType       = 'hststrpl';  % [] (HAM Small Triple)
par.coreOptics(1).seiType       = 'hamprcl';   % [] (HAM ISI [No FF L4Cs] + HAM HEPI)
par.coreOptics(1).surf1.AoI     = 0.0;         % deg                      [E0900245]
par.coreOptics(1).surf1.RoC     = -10.997;     % m                        [3]
par.coreOptics(1).surf1.plrztn  = 'U';         % [] (Unpolarized)         [E0900245]
par.coreOptics(1).surf1.rTrans  = 0.03;        % [] (in power, @ 1064 nm) [E0900245]
par.coreOptics(1).surf1.gTrans  = NaN;         % [] (in power, @ 532 nm)  [Not Spec'd, E0900245]
par.coreOptics(1).surf1.loss    = 1e-6;        % [] (in power, @ 1064 nm) [Req, E0900245]
par.coreOptics(1).surf2.AoI     = 1.45;        % deg                      [E0900245]
par.coreOptics(1).surf2.RoC     = inf;         % m                        [3]
par.coreOptics(1).surf2.plrztn  = 'S';         % [] (S-Polarized)         [E0900245]
par.coreOptics(1).surf2.rRefl   = 100e-6;      % [] (in power, @ 1064 nm) [Req, E0900245]
par.coreOptics(1).surf2.gRefl   = NaN;         % [] (in power, @ 532 nm)  [Not Spec'd, E0900245]
par.coreOptics(1).surf2.loss    = 3e-6;        % [] (in power, @ 1064 nm) [E0900245]
par.coreOptics(1).substrateLoss = 2e-7;        % [] (in power, @ 1064 nm) [Upper Limit, P. Fritschel]
par.coreOptics(1).wedgeAngle    = 1.0;         % deg                      [D0901172]
par.coreOptics(1).wedgeOrient   = '-Z';        % [] (Thick Down)          [D0901172]
par.coreOptics(1).diameter      = 0.150;       % m                        [D0901172]
par.coreOptics(1).thickness     = 0.075;       % m (at max)               [D0901172]
par.coreOptics(1).mass          = 2.92;        % kg                       [Calc'd, using 2.2e3 kg m^(-3) for Fused Silica]
par.coreOptics(1).displacement  = 0.000;       % m (for starters.)
par.coreOptics(1).position      = [ -20.205;...% m (X)                    [D0901920]
                                     -0.653;...% m (Y)                     
                                     -0.094];  % m (Z)      
                                 
% Power Recycling Mirror 2 (PR2)
par.coreOptics(2).name          = 'PR2';
par.coreOptics(2).location      = 'HAM3';
par.coreOptics(2).susType       = 'hststrpl';  % [] (HAM Small Triple)
par.coreOptics(2).seiType       = 'hamprcl';   % [] (HAM ISI [No FF L4Cs] + HAM HEPI)
par.coreOptics(2).surf1.AoI     = 0.790;       % deg                      [E0900247]
par.coreOptics(2).surf1.RoC     = -4.555;      % m                        [3]
par.coreOptics(2).surf1.plrztn  = 'P';         % [] (P-Polarization)      [E0900247]
par.coreOptics(2).surf1.rTrans  = 225e-6;      % [] (in power, @ 1064 nm) [E0900247]
par.coreOptics(2).surf1.gTrans  = 0.9;         % [] (in power, @ 532 nm)  [E0900247]
par.coreOptics(2).surf1.loss    = 1e-6;        % [] (in power, @ 1064 nm) [E0900247]
par.coreOptics(2).surf2.AoI     = 1.62;        % deg                      [E0900247]
par.coreOptics(2).surf2.RoC     = inf;         % m                        [3]
par.coreOptics(2).surf2.plrztn  = 'U';         % [] (Unpolarized)         [E0900247]
par.coreOptics(2).surf2.rRefl   = 300e-6;      % [] (in power, @ 1064 nm) [E0900247]
par.coreOptics(2).surf2.gRefl   = 0.004;       % [] (in power, @ 532 nm)  [E0900247]
par.coreOptics(2).surf2.loss    = 3e-6;        % [] (in power, @ 1064 nm) [E0900247 DOESN'T SPECIFY!!, Taken to be same as PRM]
par.coreOptics(2).substrateLoss = 2e-7;        % [] (in power, @ 1064 nm)  [Upper Limit, P. Fritschel]
par.coreOptics(2).wedgeAngle    = 0;           % deg                      [D080052]
par.coreOptics(2).wedgeOrient   = '-Z';        % [] Thick Down            [D0902838] -- D080052 doesn't show it that well
par.coreOptics(2).diameter      = 0.153;       % m                        [D080052]
par.coreOptics(2).thickness     = 0.078;       % m (at max)               [D080052]
par.coreOptics(2).mass          = 3.15;        % kg                       [Calc'd, using 2.2e3 kg m^(-3) for Fused Silica]
par.coreOptics(2).displacement  = 0.000;       % m (for starters.)
par.coreOptics(2).position      = [  -3.588;...% m (X)                    [D0901920]
                                     -0.530;...% m (Y)                    
                                     -0.085];  % m (Z)  
                                 
% Power Recycling Mirror 3 (PR3)                                 
par.coreOptics(3).name          = 'PR3';
par.coreOptics(3).location      = 'HAM2';
par.coreOptics(3).susType       = 'hltstrpl';  % [] (HAM Large Triple)
par.coreOptics(3).seiType       = 'hamprcl';   % [] (HAM ISI [No FF L4Cs] + HAM HEPI)
par.coreOptics(3).surf1.AoI     = 0.608;       % deg                      [E0900071]
par.coreOptics(3).surf1.RoC     = 36.00;       % m                        [3]
par.coreOptics(3).surf1.plrztn  = 'P';         % [] (P-Polarized)         [E0900071]
par.coreOptics(3).surf1.rTrans  = 15e-6;       % [] (in power, @ 1064 nm) [Req, E0900071]
par.coreOptics(3).surf1.gTrans  = NaN;         % [] (in power, @ 532 nm)  ["N/A", E0900071]
par.coreOptics(3).surf1.loss    = 1e-6;        % [] (in power, @ 1064 nm) [Req, E0900071]
par.coreOptics(3).surf2.AoI     = 0.608;       % deg                      [E0900071]
par.coreOptics(3).surf2.RoC     = inf;         % m                        [3]
par.coreOptics(3).surf2.plrztn  = 'P';         % [] (P-Polarized)         [E0900071]
par.coreOptics(3).surf2.rRefl   = 0.004;       % [] (in power, @ 1064 nm) [Req, E0900071]
par.coreOptics(3).surf2.gRefl   = NaN;         % [] (in power, @ 532 nm)  ["N/A", E0900071]
par.coreOptics(3).surf2.loss    = NaN;         % [] (in power, @ 1064 nm) ["N/A", E0900071]
par.coreOptics(3).substrateLoss = 2e-7;        % [] (in power, @ 1064 nm) [Upper Limit, P. Fritschel]
par.coreOptics(3).wedgeAngle    = 0.6;         % deg                      [D080662]
par.coreOptics(3).wedgeOrient   = '-Z';        % [] Thick Down            [D0902838] -- D080622 is all sortsa confusing "Bottom" looks like "Top"
par.coreOptics(3).diameter      = 0.265;       % m                        [D080662]
par.coreOptics(3).thickness     = 0.1014;      % m (at max)               [D080662]
par.coreOptics(3).mass          = 12.3;        % kg                       [Calc'd, using 2.2e3 kg m^(-3) for Fused Silica]
par.coreOptics(3).displacement  = 0.000;       % m (for starters.)
par.coreOptics(3).position      = [ -19.740;...% m (X)                    [D0901920]
                                     -0.172;...% m (Y)                    
                                     -0.095];  % m (Z) 
                                 
%%%%%            |Property      | Value        | Units (notes)            | Reference    %%%%% 
% Beam Splitter (BS)
par.coreOptics(4).name          = 'BS';
par.coreOptics(4).location      = 'BSC2';
par.coreOptics(4).susType       = 'bsfmtrpl';  % [] (BS/FM Wire Triple)
par.coreOptics(4).seiType       = 'bschepi';   % [] (BSC ISI + BSC HEPI)
par.coreOptics(4).surf1.AoI     = 45.0;        % deg                       [E0900073]
par.coreOptics(4).surf1.RoC     = inf;         % m (just fine)             [6]
par.coreOptics(4).surf1.plrztn  = 'P';         % [] (P-Polarized)          [E0900073]
par.coreOptics(4).surf1.rTrans  = 0.5;         % [] (in power, @ 1064 nm)  [Req, E0900073]
par.coreOptics(4).surf1.gTrans  = NaN;         % [] (in power, @ 532 nm)   ["N/A", E0900073]
par.coreOptics(4).surf1.loss    = 1e-6;        % [] (in power, @ 1064 nm)  [Req, E0900073]
par.coreOptics(4).surf2.AoI     = 45.0;        % deg                       [E0900073]
par.coreOptics(4).surf2.RoC     = inf;         % m (just fine)             [6]
par.coreOptics(4).surf2.plrztn  = 'P';         % [] (P-Polarized)          [E0900073]
par.coreOptics(4).surf2.rRefl   = 50e-6;       % [] (in power, @ 1064 nm)  [Goal, E0900073]
par.coreOptics(4).surf2.gRefl   = NaN;         % [] (in power, @ 532 nm)   ["N/A", E0900073]
par.coreOptics(4).surf2.loss    = 1e-6;        % [] (in power, @ 1064 nm)  [Req, E0900073]
par.coreOptics(4).substrateLoss = 2e-7;        % [] (in power, @ 1064 nm)  [Upper Limit, P. Fritschel]
par.coreOptics(4).wedgeAngle    = 0.05;        % deg                       [D080660]
par.coreOptics(4).wedgeOrient   = '+X+Y';      % [] (Thick +X, +Y)         [D080660]
par.coreOptics(4).diameter      = 0.370;       % m                         [D080660]
par.coreOptics(4).thickness     = 0.060;       % m (at max)                [D080660]
par.coreOptics(4).mass          = 14.2;        % kg                        [Calc'd, using 2.2e3 kg m^(-3) for Fused Silica]
par.coreOptics(4).displacement  = 0.000;        % m (for starters.)
par.coreOptics(4).position      = [  -0.198;...% m (X)                     [D0901920]
                                     -0.184;...% m (Y)                     
                                     -0.083];  % m (Z)                                     

%%%%% X Arm                                                                              %%%%%
%%%%%            |Property      | Value        | Units (notes)            | Reference    %%%%%
% X Arm (Thin) Compensation Plate (CPX)
par.coreOptics(5).name          = 'CPX';
par.coreOptics(5).location      = 'BSC3';
par.coreOptics(5).susType       = 'wirequad';  % [] (Wire Quadruple) 
par.coreOptics(5).seiType       = 'bschepi';   % [] (BSC ISI + BSC HEPI)
par.coreOptics(5).surf1.AoI     = 0.0;         % deg                       [E0900074]
par.coreOptics(5).surf1.RoC     = inf;         % m (just fine)             [6]
par.coreOptics(5).surf1.plrztn  = 'U';         % [] (Unpolarized)          [[ CHECKME! ]]
par.coreOptics(5).surf1.rTrans  = 1 - 20e-6;   % [] (in power, @ 1064 nm)  [Goal, E0900074]
par.coreOptics(5).surf1.gTrans  = NaN;         % [] (in power, @ 532 nm)   ["N/A", E0900074]
par.coreOptics(5).surf1.loss    = 1e-6;        % [] (in power, @ 1064 nm)  [Req, E0900074]
par.coreOptics(5).surf2.AoI     = 0.0;         % deg                       [E0900074]
par.coreOptics(5).surf2.RoC     = inf;         % m                         [6]
par.coreOptics(5).surf2.plrztn  = 'U';         % [] (Unpolarized)          [[ CHECKME! ]]
par.coreOptics(5).surf2.rRefl   = 20e-6;       % [] (in power, @ 1064 nm)  [Goal, E0900074]
par.coreOptics(5).surf2.gRefl   = NaN;         % [] (in power, @ 532 nm)   ["N/A", E0900074]
par.coreOptics(5).surf2.loss    = 1e-6;        % [] (in power, @ 1064 nm)  [Req, E0900074]
par.coreOptics(5).substrateLoss = 2e-7;        % [] (in power, @ 1064 nm)  [Upper Limit, P. Fritschel]
par.coreOptics(5).wedgeAngle    = 0.07;        % deg                       [6]
par.coreOptics(5).wedgeOrient   = '+Y';        % [] (Thick +Y)             [D1000979]    -- Error in D0902838 ??
par.coreOptics(5).diameter      = 0.340;       % m                         [D1000979]
par.coreOptics(5).thickness     = 0.100;       % m (at max)                [6]
par.coreOptics(5).mass          = 20.0;        % kg                        [6]
par.coreOptics(5).displacement  = 0.000;        % m (for starters.)
par.coreOptics(5).position      = [   4.781;...% m (X)                     [D0901920]
                                     -0.200;...% m (Y)                     
                                     -0.080];  % m (Z)  

% X Arm Input Test Mass (ITMX)
par.coreOptics(6).name          = 'ITMX';
par.coreOptics(6).location      = 'BSC3';
par.coreOptics(6).susType       = 'monoquad';  % [] (Monolithic Quadruple) 
par.coreOptics(6).seiType       = 'bschepi';   % [] (BSC ISI + BSC HEPI)
par.coreOptics(6).surf1.AoI     = 0.0;         % deg                       [E0900041]
par.coreOptics(6).surf1.RoC     = 1938;        % m                         [6]
par.coreOptics(6).surf1.plrztn  = 'U';         % [] (Unpolarized)          [[ CHECKME! ]]
par.coreOptics(6).surf1.rTrans  = 0.014;       % [] (in power, @ 1064 nm)  [Mean Req, E0900041]
par.coreOptics(6).surf1.gTrans  = 0.001;       % [] (in power, @ 532 nm)   [Goal, E0900041]
par.coreOptics(6).surf1.loss    = 0.3e-6;      % [] (in power, @ 1064 nm)  [Goal, E0900041]
par.coreOptics(6).surf2.AoI     = 0.0;         % deg                       [E0900041]
par.coreOptics(6).surf2.RoC     = inf;         % m                         [6]
par.coreOptics(6).surf2.plrztn  = 'U';         % [] (Unpolarized)          [[ CHECKME! ]]
par.coreOptics(6).surf2.rRefl   = 20e-6;       % [] (in power, @ 1064 nm)  [Goal, E0900041]
par.coreOptics(6).surf2.gRefl   = NaN;         % [] (in power, @ 532 nm)   ["N/A", E0900041]
par.coreOptics(6).surf2.loss    = 1e-6;        % [] (in power, @ 1064 nm)  [Req, E0900041]
par.coreOptics(6).substrateLoss = 2e-7;        % [] (in power, @ 1064 nm)  [Upper Limit, P. Fritschel]
par.coreOptics(6).wedgeAngle    = 0.07;        % deg                       [6]
par.coreOptics(6).wedgeOrient   = '-Z';        % [] (Thick Down)           [D080657]
par.coreOptics(6).diameter      = 0.340;       % m                         [D080657]
par.coreOptics(6).thickness     = 0.2;         % m (at max)                [6]
par.coreOptics(6).mass          = 39.5;        % kg                        [6]
par.coreOptics(6).displacement  = 0.000;       % m (for starters.)
par.coreOptics(6).position      = [   5.001;...% m (X)                     [D0902838]
                                     -0.200;...% m (Y)                    
                                     -0.080];  % m (Z)                    

% X Arm End Test Mass (ETMX)
par.coreOptics(7).name          = 'ETMX';
par.coreOptics(7).location      = 'BSC9';
par.coreOptics(7).susType       = 'monoquad';  % [] (Monolithic Quadruple) 
par.coreOptics(7).seiType       = 'bschepi';   % [] (BSC ISI + BSC HEPI)
par.coreOptics(7).surf1.AoI     = 0.0;         % deg                       [E0900068]
par.coreOptics(7).surf1.RoC     = 2250;        % m                         [6]
par.coreOptics(7).surf1.plrztn  = 'U';         % [] (Unpolarized)          [[ CHECKME! ]]
par.coreOptics(7).surf1.rTrans  = 5e-6;        % [] (in power, @ 1064 nm)  [Goal, E0900068]
par.coreOptics(7).surf1.gTrans  = 0.05;        % [] (in power, @ 532 nm)   [Goal, E0900068]
par.coreOptics(7).surf1.loss    = 0.3e-6;      % [] (in power, @ 1064 nm)  [Goal, E0900068]
par.coreOptics(7).surf2.AoI     = 0.0;         % deg                       [E0900068]
par.coreOptics(7).surf2.RoC     = inf;         % m                         [6]
par.coreOptics(7).surf2.plrztn  = 'U';         % [] (Unpolarized)          [[ CHECKME! ]]
par.coreOptics(7).surf2.rRefl   = 500e-6;      % [] (in power, @ 1064 nm)  [Req, E0900068]
par.coreOptics(7).surf2.gRefl   = 0.006;       % [] (in power, @ 532 nm)   [Log. Mean of Req, E0900068]
par.coreOptics(7).surf2.loss    = 1e-6;        % [] (in power, @ 1064 nm)  [Req, E0900068]
par.coreOptics(7).substrateLoss = 2e-7;        % [] (in power, @ 1064 nm)  [Upper Limit, P. Fritschel]
par.coreOptics(7).wedgeAngle    = 0.07;        % deg                       [6]
par.coreOptics(7).wedgeOrient   = '-Z';        % [] (Thick Down)           [D080658]
par.coreOptics(7).diameter      = 0.340;       % m                         [D080658]
par.coreOptics(7).thickness     = 0.2;         % m (at max)                [6]
par.coreOptics(7).mass          = 39.5;        % kg                        [6]
par.coreOptics(7).displacement  = 0.000;       % m (for starters.)
par.coreOptics(7).position      = [3999.501;...% m (X)                     [D0901920]
                                     -0.200;...% m (Y)                    
                                     -0.080];  % m (Z)

% X Arm End Reaction Mass (ERMX)
par.coreOptics(8).name          = 'ERMX';
par.coreOptics(8).location      = 'BSC9';
par.coreOptics(8).susType       = 'wirequad';  % [] (Wire Quadruple) 
par.coreOptics(8).seiType       = 'bschepi';   % [] (BSC ISI + BSC HEPI)
par.coreOptics(8).surf1.AoI     = 0.0;         % deg                       [E0900140]
par.coreOptics(8).surf1.RoC     = inf;         % m (just fine.)            [6]
par.coreOptics(8).surf1.plrztn  = 'U';         % [] (Unpolarized)          [[ CHECKME! ]]
par.coreOptics(8).surf1.rTrans  = 1 - 1000e-6; % [] (in power, @ 1064 nm)  [Req, E0900140]
par.coreOptics(8).surf1.gTrans  = 1 - 1000e-6; % [] (in power, @ 532 nm)   [Req, E0900140]
par.coreOptics(8).surf1.loss    = 0;           % [] (in power, @ 1064 nm)  [[ FIXME!! ]]
par.coreOptics(8).surf2.AoI     = 0.0;         % deg                       [E0900140]
par.coreOptics(8).surf2.RoC     = inf;         % m                         [6]
par.coreOptics(8).surf2.plrztn  = 'U';         % [] (Unpolarized)          [[ CHECKME! ]]
par.coreOptics(8).surf2.rRefl   = 1000e-6;     % [] (in power, @ 1064 nm)  [Req, E0900140]
par.coreOptics(8).surf2.gRefl   = 1000e-6;     % [] (in power, @ 532 nm)   [Req, E0900140]
par.coreOptics(8).surf2.loss    = 0;           % [] (in power, @ 1064 nm)  [[ FIXME!! ]]
par.coreOptics(8).substrateLoss = 2e-7;        % [] (in power, @ 1064 nm)  [Upper Limit, P. Fritschel]
par.coreOptics(8).diameter      = 0.340;       % m                         [D080116]
par.coreOptics(8).thickness     = 0.130;       % m                         [6]
par.coreOptics(8).wedgeAngle    = 0.04;        % m                         [D080116]
par.coreOptics(8).wedgeOrient   = '+Y';        % [] (Thick +Y)             [D080116]
par.coreOptics(8).mass          = 26.0;        % kg                        [Calc'd, using 2.2e3 kg m^(-3) for Fused Silica]
par.coreOptics(8).displacement  = 0.000;       % m (for starters.)
par.coreOptics(8).position      = [     NaN;...% m (X)                     [[ FIXME!! ]]
                                        NaN;...% m (Y)                     [[ FIXME!! ]]
                                        NaN];  % m (Z)                     [[ FIXME!! ]]
                  
%%%%% Y Arm                                                                              %%%%%
%%%%%            |Property      | Value        | Units (notes)            | Reference    %%%%%
% Y Arm (Thin) Compensation Plate (CPY)
par.coreOptics(9).name          = 'CPY';
par.coreOptics(9).location      = 'BSC1';
par.coreOptics(9).susType       = 'wirequad';  % [] (Wire Quadruple) 
par.coreOptics(9).seiType       = 'bschepi';   % [] (BSC ISI + BSC HEPI)
par.coreOptics(9).surf1.AoI     = 0.0;         % deg                       [E0900074]
par.coreOptics(9).surf1.RoC     = inf;         % m (just fine)             [6]
par.coreOptics(9).surf1.plrztn  = 'U';         % [] (Unpolarized)          [[ CHECKME! ]]
par.coreOptics(9).surf1.rTrans  = 1 - 20e-6;   % [] (in power, @ 1064 nm)  [Goal, E0900074]
par.coreOptics(9).surf1.gTrans  = NaN;         % [] (in power, @ 532 nm)   ["N/A", E0900074]
par.coreOptics(9).surf1.loss    = 1e-6;        % [] (in power, @ 1064 nm)  [Req, E0900074]
par.coreOptics(9).surf2.AoI     = 0.0;         % deg                       [E0900074]
par.coreOptics(9).surf2.RoC     = inf;         % m                         [6]
par.coreOptics(9).surf2.plrztn  = 'U';         % [] (Unpolarized)          [[ CHECKME! ]]
par.coreOptics(9).surf2.rRefl   = 20e-6;       % [] (in power, @ 1064 nm)  [Goal, E0900074]
par.coreOptics(9).surf2.gRefl   = NaN;         % [] (in power, @ 532 nm)   ["N/A", E0900074]
par.coreOptics(9).surf2.loss    = 1e-6;        % [] (in power, @ 1064 nm)  [Req, E0900074]
par.coreOptics(9).substrateLoss = 2e-7;        % [] (in power, @ 1064 nm)  [Upper Limit, P. Fritschel]
par.coreOptics(9).wedgeAngle    = 0.07;        % deg                       [6]
par.coreOptics(9).wedgeOrient   = '-X';        % [] (Thick -X)             [D1000979]    -- Error in D0902838 ??
par.coreOptics(9).diameter      = 0.340;       % m                         [D1000979]
par.coreOptics(9).thickness     = 0.100;       % m (at max)                [6]
par.coreOptics(9).mass          = 20.0;        % kg                        [6]
par.coreOptics(9).displacement  = 0.000;        % m (for starters.)
par.coreOptics(9).position      = [  -0.200;...% m (X)                     [D0901920]
                                      4.778;...% m (Y)                     
                                     -0.080];  % m (Z)    

% Y Arm Input Test Mass (ITMY)
par.coreOptics(10).name          = 'ITMY';
par.coreOptics(10).location      = 'BSC1';
par.coreOptics(10).susType       = 'monoquad';  % [] (Monolithic Quadruple) 
par.coreOptics(10).seiType       = 'bschepi';   % [] (BSC ISI + BSC HEPI)
par.coreOptics(10).surf1.AoI     = 0.0;         % deg                      [E0900041]
par.coreOptics(10).surf1.RoC     = 1938;        % m                        [6]
par.coreOptics(10).surf1.plrztn  = 'U';         % [] (Unpolarized)         [[ CHECKME! ]]
par.coreOptics(10).surf1.rTrans  = 0.014;       % [] (in power, @ 1064 nm) [Mean Req, E0900041]
par.coreOptics(10).surf1.gTrans  = 0.001;       % [] (in power, @ 532 nm)  [Goal, E0900041]
par.coreOptics(10).surf1.loss    = 0.3e-6;      % [] (in power, @ 1064 nm) [Goal, E0900041]
par.coreOptics(10).surf2.AoI     = 0.0;         % deg                      [E0900041]
par.coreOptics(10).surf2.RoC     = inf;         % m                        [6]
par.coreOptics(10).surf2.plrztn  = 'U';         % [] (Unpolarized)         [[ CHECKME! ]]
par.coreOptics(10).surf2.rRefl   = 20e-6;       % [] (in power, @ 1064 nm) [Goal, E0900041]
par.coreOptics(10).surf2.gRefl   = NaN;         % [] (in power, @ 532 nm)  ["N/A", E0900041]
par.coreOptics(10).surf2.loss    = 1e-6;        % [] (in power, @ 1064 nm) [Req, E0900041]
par.coreOptics(10).substrateLoss = 2e-7;        % [] (in power, @ 1064 nm) [Upper Limit, P. Fritschel]
par.coreOptics(10).wedgeAngle    = 0.07;        % deg                      [6]
par.coreOptics(10).wedgeOrient   = '-Z';        % [] (Thick Down)          [D080657]
par.coreOptics(10).diameter      = 0.340;       % m                        [D080657]
par.coreOptics(10).thickness     = 0.2;         % m (at max)               [6]
par.coreOptics(10).mass          = 39.5;        % kg                       [6]
par.coreOptics(10).displacement  = 0.000;       % m (for starters.)
par.coreOptics(10).position      = [  -0.200;...% m (X)                    [D0901920]
                                       4.998;...% m (Y)                     
                                      -0.080];  % m (Z)       

% Y Arm End Test Mass (ETMY)
par.coreOptics(11).name          = 'ETMY';
par.coreOptics(11).location      = 'BSC10';
par.coreOptics(11).susType       = 'monoquad';  % [] (Monolithic Quadruple) 
par.coreOptics(11).seiType       = 'bschepi';   % [] (BSC ISI + BSC HEPI)
par.coreOptics(11).surf1.AoI     = 0.0;         % deg                      [E0900068]
par.coreOptics(11).surf1.RoC     = 2250;        % m                        [6]
par.coreOptics(11).surf1.plrztn  = 'U';         % [] (Unpolarized)         [[ CHECKME! ]]
par.coreOptics(11).surf1.rTrans  = 5e-6;        % [] (in power, @ 1064 nm) [Goal, E0900068]
par.coreOptics(11).surf1.gTrans  = 0.05;        % [] (in power, @ 532 nm)  [Goal, E0900068]
par.coreOptics(11).surf1.loss    = 0.3e-6;      % [] (in power, @ 1064 nm) [Goal, E0900068]
par.coreOptics(11).surf2.AoI     = 0.0;         % deg                      [E0900068]
par.coreOptics(11).surf2.RoC     = inf;         % m                        [6]
par.coreOptics(11).surf2.plrztn  = 'U';         % [] (Unpolarized)         [[ CHECKME! ]]
par.coreOptics(11).surf2.rRefl   = 500e-6;      % [] (in power, @ 1064 nm) [Req, E0900068]
par.coreOptics(11).surf2.gRefl   = 0.006;       % [] (in power, @ 532 nm)  [Log. Mean of Req, E0900068]
par.coreOptics(11).surf2.loss    = 1e-6;        % [] (in power, @ 1064 nm) [Req, E0900068]
par.coreOptics(11).substrateLoss = 2e-7;        % [] (in power, @ 1064 nm) [Upper Limit, P. Fritschel]
par.coreOptics(11).wedgeAngle    = 0.07;        % deg                      [6]
par.coreOptics(11).wedgeOrient   = '-Z';        % [] (Thick Down)          [D080658]
par.coreOptics(11).diameter      = 0.340;       % m                        [D080658]
par.coreOptics(11).thickness     = 0.2;         % m (at max)               [6]
par.coreOptics(11).mass          = 39.5;        % kg                       [6]
par.coreOptics(11).displacement  = 0.000;       % m (for starters.)
par.coreOptics(11).position      = [  -0.200;...% m (X)                    [D0901920]
                                    3999.498;...% m (Y)                 
                                      -0.080];  % m (Z)                    

% Y Arm End Reaction Mass (ERMY)
par.coreOptics(12).name          = 'ERMY';
par.coreOptics(12).location      = 'BSC10';
par.coreOptics(12).susType       = 'wirequad';  % [] (Wire Quadruple)
par.coreOptics(12).seiType       = 'bschepi';   % [] (BSC ISI + BSC HEPI)
par.coreOptics(12).surf1.AoI     = 0.0;         % deg                      [E0900140]
par.coreOptics(12).surf1.RoC     = inf;         % m (just fine.)           [6]
par.coreOptics(12).surf1.plrztn  = 'U';         % [] (Unpolarized)         [[ CHECKME! ]]
par.coreOptics(12).surf1.rTrans  = 1 - 1000e-6; % [] (in power, @ 1064 nm) [Req, E0900140]
par.coreOptics(12).surf1.gTrans  = 1 - 1000e-6; % [] (in power, @ 532 nm)  [Req, E0900140]
par.coreOptics(12).surf1.loss    = 0;           % [] (in power, @ 1064 nm) [[ FIXME!! ]]
par.coreOptics(12).surf2.AoI     = 0.0;         % deg                      [E0900140]
par.coreOptics(12).surf2.RoC     = inf;         % m                        [6]
par.coreOptics(12).surf2.plrztn  = 'U';         % [] (Unpolarized)         [[ CHECKME! ]]
par.coreOptics(12).surf2.rRefl   = 1000e-6;     % [] (in power, @ 1064 nm) [Req, E0900140]
par.coreOptics(12).surf2.gRefl   = 1000e-6;     % [] (in power, @ 532 nm)  [Req, E0900140]
par.coreOptics(12).surf2.loss    = 0;           % [] (in power, @ 1064 nm) [[ FIXME!! ]]
par.coreOptics(12).substrateLoss = 2e-7;        % [] (in power, @ 1064 nm) [Upper Limit, P. Fritschel]
par.coreOptics(12).diameter      = 0.340;       % m                        [D080116]
par.coreOptics(12).thickness     = 0.130;       % m                        [6]
par.coreOptics(12).wedgeAngle    = 0.04;        % m                        [D080116]
par.coreOptics(12).wedgeOrient   = '-X';        % [] (Thick -X)            [D0902838]
par.coreOptics(12).mass          = 26.0;        % kg                       [Calc'd, using 2.2e3 kg m^(-3) for Fused Silica]
par.coreOptics(12).displacement  = 0.000;       % m (for starters.)
par.coreOptics(12).position      = [     NaN;...% m (X)                    [[ FIXME!! ]]
                                        NaN;...% m (Y)                     [[ FIXME!! ]]
                                        NaN];  % m (Z)                     [[ FIXME!! ]]

%%%%% Singal Recycling Cavity                                                             %%%%%
%%%%%             |Property      | Value        | Units (notes)            | Reference    %%%%%
% Signal Recycling Mirror 3 (SR3)                  
par.coreOptics(13).name          = 'SR3';
par.coreOptics(13).location      = 'HAM5';
par.coreOptics(13).susType       = 'hltstrpl';  % [] (HAM Large Triple)
par.coreOptics(13).seiType       = 'hamsrcl';   % [] (HAM ISI [w/ FF L4Cs] + HAM HEPI)
par.coreOptics(13).surf1.AoI     = 0.774;       % deg                      [E0900069]
par.coreOptics(13).surf1.RoC     = 36.00;       % m                        [3]
par.coreOptics(13).surf1.plrztn  = 'P';         % [] (P-Polarized)         [E0900069]
par.coreOptics(13).surf1.rTrans  = 15e-6;       % [] (in power, @ 1064 nm) [Req, E0900069]
par.coreOptics(13).surf1.gTrans  = NaN;         % [] (in power, @ 532 nm)  ["N/A", E0900069]
par.coreOptics(13).surf1.loss    = 1e-6;        % [] (in power, @ 1064 nm) [Req, E0900069]
par.coreOptics(13).surf2.AoI     = 0.774;       % deg                      [E0900069]
par.coreOptics(13).surf2.RoC     = inf;         % m                        [6]
par.coreOptics(13).surf2.plrztn  = 'P';         % [] (P-Polarized)         [E0900069]
par.coreOptics(13).surf2.rRefl   = 0.0004;      % [] (in power, @ 1064 nm) [Req, E0900069]
par.coreOptics(13).surf2.gRefl   = NaN;         % [] (in power, @ 532 nm)  ["N/A", E0900069]
par.coreOptics(13).surf2.loss    = NaN;         % [] (in power, @ 1064 nm) ["N/A", E0900069]
par.coreOptics(13).substrateLoss = 2e-7;        % [] (in power, @ 1064 nm)  [Upper Limit, P. Fritschel]
par.coreOptics(13).wedgeAngle    = 0.6;         % deg                      [D080664]
par.coreOptics(13).wedgeOrient   = '-Z';        % [] Thick Down            [D080664]
par.coreOptics(13).diameter      = 0.265;       % m                        [D080664]
par.coreOptics(13).thickness     = 0.1014;      % m (at max)               [D080664]
par.coreOptics(13).mass          = 12.3;        % kg                       [Calc'd, using 2.2e3 kg m^(-3) for Fused Silica]
par.coreOptics(13).displacement  = 0.000;       % m (for starters.)
par.coreOptics(13).position      = [  -0.160;...% m (X)                    [D0901920]
                                     -19.615;...% m (Y)                    
                                      -0.095];  % m (Z) 
           
% Signal Recycling Mirror 2 (SR2)            
par.coreOptics(14).name          = 'SR2';
par.coreOptics(14).location      = 'HAM4';
par.coreOptics(14).susType       = 'hststrpl';  % [] (HAM Small Triple)
par.coreOptics(14).seiType       = 'hamsrcl';   % [] (HAM ISI [w/ FF L4Cs] + HAM HEPI)
par.coreOptics(14).surf1.AoI     = 0.870;       % deg                      [E0900248]
par.coreOptics(14).surf1.RoC     = -6.427;      % m                        [3]
par.coreOptics(14).surf1.plrztn  = 'P';         % [] (P-Polarized)         [E0900248]
par.coreOptics(14).surf1.rTrans  = 15e-6;       % [] (in power, @ 1064 nm) [E0900248]
par.coreOptics(14).surf1.gTrans  = NaN;         % [] (in power, @ 532 nm)  [Not Spec'd, E0900248]
par.coreOptics(14).surf1.loss    = 1e-6;        % [] (in power, @ 1064 nm) [Req, E0900248]
par.coreOptics(14).surf2.AoI     = 1.72;        % deg                      [E0900248]
par.coreOptics(14).surf2.RoC     = inf;         % m                        [6]
par.coreOptics(14).surf2.plrztn  = 'U';         % [] (Unpolarized)         [E0900248]
par.coreOptics(14).surf2.rRefl   = 300e-6;      % [] (in power, @ 1064 nm) [E0900248]
par.coreOptics(14).surf2.gRefl   = NaN;         % [] (in power, @ 532 nm)  [Not Spec'd, E0900248]
par.coreOptics(14).surf2.loss    = 3e-6;        % [] (in power, @ 1064 nm) [E0900248, DOESN'T SPECIFY!!, Taken to be same as SRM]
par.coreOptics(14).substrateLoss = 2e-7;        % [] (in power, @ 1064 nm) [Upper Limit, P. Fritschel]
par.coreOptics(14).wedgeAngle    = 1.0;         % deg                      [D0901178]
par.coreOptics(14).wedgeOrient   = '-Z';        % [] Thick Down            [D0901178]
par.coreOptics(14).diameter      = 0.150;       % m                        [D0901178]
par.coreOptics(14).thickness     = 0.075;       % m (at max)               [D0901178]
par.coreOptics(14).mass          = 2.92;        % kg                       [Calc'd, using 2.2e3 kg m^(-3) for Fused Silica]
par.coreOptics(14).displacement  = 0.000;       % m (for starters.)
par.coreOptics(14).position      = [  -0.594;...% m (X)                    [D0901920]
                                      -4.160;...% m (Y)                    
                                      -0.104];  % m (Z)  

% Signal Recycling Mirror (SRM)     
par.coreOptics(15).name          = 'SRM';
par.coreOptics(15).location      = 'HAM5';
par.coreOptics(15).susType       = 'hststrpl';  % [] (HAM Small Triple)
par.coreOptics(15).seiType       = 'hamsrcl';   % [] (HAM ISI [w/ FF L4Cs] + HAM HEPI)
par.coreOptics(15).surf1.AoI     = 0.0;         % deg                      [E0900246]
par.coreOptics(15).surf1.RoC     = -5.6938;     % m                        [3]
par.coreOptics(15).surf1.plrztn  = 'U';         % [] (Unpolarized)         [E0900246]
par.coreOptics(15).surf1.rTrans  = srmTrans;    % [] (in power, @ 1064 nm) [User Input, Nominal Mode 1b is 0.2]
par.coreOptics(15).surf1.gTrans  = NaN;         % [] (in power, @ 532 nm)  [[ FIXME!! ]]
par.coreOptics(15).surf1.loss    = 1e-6;        % [] (in power, @ 1064 nm) [E0900246]
par.coreOptics(15).surf2.AoI     = 1.45;        % deg                      [E0900246]
par.coreOptics(15).surf2.RoC     = inf;         % m                        [6]
par.coreOptics(15).surf2.plrztn  = 'S';         % [] (S-Polarized)         [E0900246]
par.coreOptics(15).surf2.rRefl   = 50e-6;       % [] (in power, @ 1064 nm) [Goal, E0900246]
par.coreOptics(15).surf2.gRefl   = NaN;         % [] (in power, @ 532 nm)  [[ FIXME!! ]]
par.coreOptics(15).surf2.loss    = 3e-6;        % [] (in power, @ 1064 nm) [E0900246]
par.coreOptics(15).substrateLoss = 2e-7;        % [] (in power, @ 1064 nm) [Upper Limit, P. Fritschel]
par.coreOptics(15).wedgeAngle    = 1.0;         % deg                      [D0901174]
par.coreOptics(15).wedgeOrient   = '-Z';        % [] Thick Down            [D0901174]
par.coreOptics(15).diameter      = 0.150;       % m                        [D0901174]
par.coreOptics(15).thickness     = 0.075;       % m (at max)               [D0901174]
par.coreOptics(15).mass          = 2.92;        % kg                       [Calc'd, using 2.2e3 kg m^(-3) for Fused Silica]
par.coreOptics(15).displacement  = 0.000;       % m (for starters.)
par.coreOptics(15).position      = [   0.305;...% m (X)                    [D0901920]
                                     -19.877;...% m (Y)                    
                                      -0.114];  % m (Z)                    
               
%% 6 %% Output Optics %% %%
%%%%%           | Property     | Value        | Units (notes)                    | Reference    %%%%% 
% Output Faraday Isolator (OFI)
par.outOptics(1).name          = 'OFI';
par.outOptics(1).location      = 'HAM2';
par.outOptics(1).susType       = 'frdysngl';  % [] (Faraday Single)
par.outOptics(1).seiType       = 'hamsrcl';   % [] (HAM ISI [w/ FF L4Cs] + HAM HEPI)
par.outOptics(1).surf1.AoI     = 0;           % deg                        []
par.outOptics(1).surf1.RoC     = 0;           % m                          []
par.outOptics(1).surf1.plrztn  = '';          % []                         []
par.outOptics(1).surf1.rTrans  = 0;           % [] (in power, @ 1064 nm)   []
par.outOptics(1).surf1.gTrans  = 0;           % [] (in power, @ 532 nm)    []
par.outOptics(1).surf1.loss    = 0;           % [] (in power, @ 1064 nm)   []
par.outOptics(1).surf2.AoI     = 0;           % deg                        []
par.outOptics(1).surf2.RoC     = 0;           % m                          []
par.outOptics(1).surf2.RoC     = 0;           % m                          []
par.outOptics(1).surf2.plrztn  = '';          % []                         []
par.outOptics(1).surf2.rRefl   = 0;           % [] (in power, @ 1064 nm)   []
par.outOptics(1).surf2.gRefl   = 0;           % [] (in power, @ 532 nm)    []
par.outOptics(1).surf2.loss    = 0;           % [] (in power, @ 1064 nm)   []
par.outOptics(1).substrateLoss = 0;           % [] (in power, @ 1064 nm)   []
par.outOptics(1).wedgeAngle    = 0;           % deg                        []
par.outOptics(1).wedgeOrient   = '';          % [] (Thick)                 []
par.outOptics(1).diameter      = 0;           % m                          []
par.outOptics(1).thickness     = 0;           % m (at max)                 []
par.outOptics(1).mass          = 0;           % kg                         []
par.outOptics(1).displacement  = 0;           % m (for starters.)
par.outOptics(1).position      = [0;...       % m (X)                      []
                                  0;...       % m (Y)                    
                                  0];         % m (Z)                

% AS Output Mode Matching Telescope
% Block Diagram D1000342
% Output Mode Matching Telescope 1 (OMMT1)
par.outOptics(2).name          = 'OMMT1';
par.outOptics(2).location      = 'HAM6';
par.outOptics(2).susType       = 'ommtsngl';  % "Tip-Tilts" with blade springs
par.outOptics(2).seiType       = 'hamprcl';   % [] (HAM ISI [No FF L4Cs] + HAM HEPI) 
par.outOptics(2).surf1.AoI     = 5.45;        % deg                        [calc'd from T1000317]
par.outOptics(2).surf1.RoC     = 4.6;         % m                          [T1000317]
par.outOptics(2).surf1.plrztn  = 'P';         % [] P-Polarized             [[FIXME!!]]
par.outOptics(2).surf1.rTrans  = 100e-6;      % [] (in power, @ 1064 nm)   [[FIXME!!]]
par.outOptics(2).surf1.gTrans  = NaN;         % [] (in power, @ 532 nm)    [No Need]
par.outOptics(2).surf1.loss    = 0.0;         % [] (in power, @ 1064 nm)   [[FIXME!!]]
par.outOptics(2).surf2.AoI     = 0.0;         % deg                        [[FIXME!!]]
par.outOptics(2).surf2.RoC     = inf;         % m                          [[FIXME!!]]
par.outOptics(2).surf2.plrztn  = 'U';         % [] Unpolarized             [[FIXME!!]]
par.outOptics(2).surf2.rRefl   = 100e-6;      % [] (in power, @ 1064 nm)   [[FIXME!!]]
par.outOptics(2).surf2.gRefl   = NaN;         % [] (in power, @ 532 nm)    [No Need]
par.outOptics(2).surf2.loss    = 0.0;         % [] (in power, @ 1064 nm)   [[FIXME!!]]
par.outOptics(2).substrateLoss = 2e-7;        % [] (in power, @ 1064 nm)   [Upper Limit, P. Fritschel]
par.outOptics(2).wedgeAngle    = 0.0;         % deg                        [They're just CVI optics]
par.outOptics(2).wedgeOrient   = 'None';      % [] (No Wedge)              [They're just CVI optics]
par.outOptics(2).diameter      = 0.0508;      % m (2")                     [T1000042]
par.outOptics(2).thickness     = 0.0095;      % m (3/8", at max)           [T1000042]
par.outOptics(2).mass          = 0.0424;      % kg                         [Calc'd, using 2.2e3 kg m^(-3) for Fused Silica]
par.outOptics(2).displacement  = 0.0;         % m (for starters.)
par.outOptics(2).position      = [0;...       % m (X)                      []
                                  0;...       % m (Y)                    
                                  0];         % m (Z)

% Output Mode Matching Telescope 2 (OMMT2)
par.outOptics(3).name          = 'OMMT2';
par.outOptics(3).location      = 'HAM6';
par.outOptics(3).susType       = 'ommtsngl';  % "Tip-Tilts" with blade springs
par.outOptics(3).seiType       = 'hamprcl';   % [] (HAM ISI [No FF L4Cs] + HAM HEPI) 
par.outOptics(3).surf1.AoI     = 7.0717;      % deg                        [calc'd from T1000317]
par.outOptics(3).surf1.RoC     = 1.7;         % m                          [T1000317]
par.outOptics(3).surf1.plrztn  = 'P';         % [] P-Polarized             [[FIXME!!]]
par.outOptics(3).surf1.rTrans  = 100e-6;      % [] (in power, @ 1064 nm)   [[FIXME!!]]
par.outOptics(3).surf1.gTrans  = NaN;         % [] (in power, @ 532 nm)    [No Need]
par.outOptics(3).surf1.loss    = 0.0;         % [] (in power, @ 1064 nm)   [[FIXME!!]]
par.outOptics(3).surf2.AoI     = 0.0;         % deg                        [[FIXME!!]]
par.outOptics(3).surf2.RoC     = inf;         % m                          [[FIXME!!]]
par.outOptics(3).surf2.plrztn  = 'U';         % [] Unpolarized             [[FIXME!!]]
par.outOptics(3).surf2.rRefl   = 100e-6;      % [] (in power, @ 1064 nm)   [[FIXME!!]]
par.outOptics(3).surf2.gRefl   = NaN;         % [] (in power, @ 532 nm)    [No Need]
par.outOptics(3).surf2.loss    = 0.0;         % [] (in power, @ 1064 nm)   [[FIXME!!]]
par.outOptics(3).substrateLoss = 2e-7;        % [] (in power, @ 1064 nm)   [Upper Limit, P. Fritschel]
par.outOptics(3).wedgeAngle    = 0.0;         % deg                        [They're just CVI optics]
par.outOptics(3).wedgeOrient   = 'None';      % [] (No Wedge)              [They're just CVI optics]
par.outOptics(3).diameter      = 0.0508;      % m (2")                     [T1000042]
par.outOptics(3).thickness     = 0.0095;      % m (3/8", at max)           [T1000042]
par.outOptics(3).mass          = 0.0424;      % kg                         [Calc'd, using 2.2e3 kg m^(-3) for Fused Silica]
par.outOptics(3).displacement  = 0;           % m (for starters.)
par.outOptics(3).position      = [0;...       % m (X)                      []
                                  0;...       % m (Y)                    
                                  0];         % m (Z)

% Output Mode Matching Telescope 3 (OMMT3)
par.outOptics(4).name          = 'OMMT3';
par.outOptics(4).location      = 'HAM6';
par.outOptics(4).susType       = 'ommtsngl';  % "Tip-Tilts" with blade springs
par.outOptics(4).seiType       = 'hamprcl';   % [] (HAM ISI [No FF L4Cs] + HAM HEPI) 
par.outOptics(4).surf1.AoI     = 45;          % deg                        [[FIXME!!]]
par.outOptics(4).surf1.RoC     = inf;         % m                          [T1000317]
par.outOptics(4).surf1.plrztn  = 'P';         % [] P-Polarized             [[FIXME!!]]
par.outOptics(4).surf1.rTrans  = 100e-6;      % [] (in power, @ 1064 nm)   [[FIXME!!]]
par.outOptics(4).surf1.gTrans  = NaN;         % [] (in power, @ 532 nm)    [No Need]
par.outOptics(4).surf1.loss    = 0.0;         % [] (in power, @ 1064 nm)   [[FIXME!!]]
par.outOptics(4).surf2.AoI     = 0.0;         % deg                        [[FIXME!!]]
par.outOptics(4).surf2.RoC     = inf;         % m                          [[FIXME!!]]
par.outOptics(4).surf2.plrztn  = 'U';         % [] Unpolarized             [[FIXME!!]]
par.outOptics(4).surf2.rRefl   = 100e-6;      % [] (in power, @ 1064 nm)   [[FIXME!!]]
par.outOptics(4).surf2.gRefl   = NaN;         % [] (in power, @ 532 nm)    [No Need]
par.outOptics(4).surf2.loss    = 0.0;         % [] (in power, @ 1064 nm)   [[FIXME!!]]
par.outOptics(4).substrateLoss = 2e-7;        % [] (in power, @ 1064 nm)   [Upper Limit, P. Fritschel]
par.outOptics(4).wedgeAngle    = 0.0;         % deg                        [They're just CVI optics]
par.outOptics(4).wedgeOrient   = 'None';      % [] (No Wedge)              [They're just CVI optics]
par.outOptics(4).diameter      = 0.0508;      % m (2")                     [T1000042]
par.outOptics(4).thickness     = 0.0095;      % m (3/8", at max)           [T1000042]
par.outOptics(4).mass          = 0.0424;      % kg                         [Calc'd, using 2.2e3 kg m^(-3) for Fused Silica]
par.outOptics(4).displacement  = 0;           % m (for starters.)
par.outOptics(4).position      = [0;...       % m (X)                      []
                                  0;...       % m (Y)                    
                                  0];         % m (Z)

%% 7 %% OMC Optics %% %%
% Dimensions T1080144
%%%%%           |Property      | Value        | Units (notes)                     | Reference    %%%%% 
% Output Mode Cleaner Steering Mirror (OMCSM)
par.omcOptics(1).name          = 'OMCSM';
par.omcOptics(1).location      = 'HAM6';
par.omcOptics(1).susType       = 'omcdoubl';
par.omcOptics(1).seiType       = 'hamprcl';   % [] (HAM ISI [No FF L4Cs] + HAM HEPI) 
par.omcOptics(1).surf1.AoI     = 45;          % deg                        [T080144]
par.omcOptics(1).surf1.RoC     = inf;         % m (just fine.)             [T080144]
par.omcOptics(1).surf1.plrztn  = '';          % []                         []
par.omcOptics(1).surf1.rTrans  = 3000e-6;     % [] (in power, @ 1064 nm)   [T080144]
par.omcOptics(1).surf1.gTrans  = NaN;         % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.omcOptics(1).surf1.loss    = 0;           % [] (in power, @ 1064 nm)   []
par.omcOptics(1).surf2.AoI     = 45;          % deg                        [T080144]
par.omcOptics(1).surf2.RoC     = inf;         % m                          [T080144]
par.omcOptics(1).surf2.plrztn  = '';          % []                         []
par.omcOptics(1).surf2.rRefl   = 0;           % [] (in power, @ 1064 nm)   []
par.omcOptics(1).surf2.gRefl   = NaN;         % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.omcOptics(1).surf2.loss    = 0;           % [] (in power, @ 1064 nm)   []
par.omcOptics(1).substrateLoss = 2e-7;        % [] (in power, @ 1064 nm)   [Upper Limit, P. Fritschel]
par.omcOptics(1).wedgeAngle    = 0.000;       % deg                        [They're just CVI optics]
par.omcOptics(1).wedgeOrient   = 'None';      % []                         [They're just CVI optics]
par.omcOptics(1).diameter      = 0.0254;      % m (1")                     [T1000276]
par.omcOptics(1).thickness     = 0.00635;     % m (1/4", at max)           [Guess from T1000276] ("It's either 3/8" or 1/4" " -- Nic Smith)
par.omcOptics(1).mass          = 0.00787;     % kg                         [Calc'd, using 2.2e3 kg m^(-3) for Fused Silica]
par.omcOptics(1).displacement  = 0;           % m (for starters.)
par.omcOptics(1).position      = [0;...       % m (X)                      []
                                  0;...       % m (Y)                    
                                  0];         % m (Z)

% Output Mode Cleaner Mirror 1 (OMCM1)                              
par.omcOptics(2).name          = 'OMCM1';
par.omcOptics(2).location      = 'HAM6';
par.omcOptics(2).susType       = 'omcdoubl';
par.omcOptics(2).seiType       = 'hamprcl';   % [] (HAM ISI [No FF L4Cs] + HAM HEPI) 
par.omcOptics(2).surf1.AoI     = 6.0;         % deg                        [T080114]
par.omcOptics(2).surf1.RoC     = inf;         % m                          [T080114]
par.omcOptics(2).surf1.plrztn  = '';          % []                         []
par.omcOptics(2).surf1.rTrans  = 8000e-6;     % [] (in power, @ 1064 nm)   [T1000276]
par.omcOptics(2).surf1.gTrans  = NaN;         % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.omcOptics(2).surf1.loss    = 0;           % [] (in power, @ 1064 nm)   []
par.omcOptics(2).surf2.AoI     = 6.0;         % deg                        [[ CHECKME! ]]
par.omcOptics(2).surf2.RoC     = inf;         % m                          [[ CHECKME! ]]
par.omcOptics(2).surf2.plrztn  = '';          % []                         []
par.omcOptics(2).surf2.rRefl   = 0;           % [] (in power, @ 1064 nm)   []
par.omcOptics(2).surf2.gRefl   = NaN;         % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.omcOptics(2).surf2.loss    = 0;           % [] (in power, @ 1064 nm)   []
par.omcOptics(2).substrateLoss = 2e-7;        % [] (in power, @ 1064 nm)   [Upper Limit, P. Fritschel]
par.omcOptics(2).wedgeAngle    = 0.000;       % deg                        [They're just CVI optics]
par.omcOptics(2).wedgeOrient   = 'None';      % []                         [They're just CVI optics]
par.omcOptics(2).diameter      = 0.0254;      % m (1")                     [T1000276]
par.omcOptics(2).thickness     = 0.00635;     % m (1/4", at max)           [Guess from T1000276] ("It's either 3/8" or 1/4" " -- Nic Smith)
par.omcOptics(2).mass          = 0.00787;     % kg                         [Calc'd, using 2.2e3 kg m^(-3) for Fused Silica]
par.omcOptics(2).displacement  = 0;           % m (for starters.)
par.omcOptics(2).position      = [0;...       % m (X)                      []
                                  0;...       % m (Y)                    
                                  0];         % m (Z)

% Output Mode Cleaner Mirror 2 (OMCM2)                              
par.omcOptics(3).name          = 'OMCM2';
par.omcOptics(3).location      = 'HAM6';
par.omcOptics(3).susType       = 'omcdoubl';
par.omcOptics(3).seiType       = 'hamprcl';   % [] (HAM ISI [No FF L4Cs] + HAM HEPI) 
par.omcOptics(3).surf1.AoI     = 6.0;         % deg                        [T080144]
par.omcOptics(3).surf1.RoC     = 2.0;         % m                          [T080144]
par.omcOptics(3).surf1.plrztn  = '';          % []                         []
par.omcOptics(3).surf1.rTrans  = 30e-6;       % [] (in power, @ 1064 nm)   [mean([H1M2 H1M4]), T080144]
par.omcOptics(3).surf1.gTrans  = NaN;         % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.omcOptics(3).surf1.loss    = 0;           % [] (in power, @ 1064 nm)   []
par.omcOptics(3).surf2.AoI     = 6.0;         % deg                        [[ CHECKME! ]]
par.omcOptics(3).surf2.RoC     = inf;         % m                          [[ CHECKME! ]]
par.omcOptics(3).surf2.plrztn  = '';          % []                         []
par.omcOptics(3).surf2.rRefl   = 0;           % [] (in power, @ 1064 nm)   []
par.omcOptics(3).surf2.gRefl   = NaN;         % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.omcOptics(3).surf2.loss    = 0;           % [] (in power, @ 1064 nm)   []
par.omcOptics(3).substrateLoss = 2e-7;        % [] (in power, @ 1064 nm)   [Upper Limit, P. Fritschel]
par.omcOptics(3).wedgeAngle    = 0.000;       % deg                        [They're just CVI optics]
par.omcOptics(3).wedgeOrient   = 'None';      % []                         [They're just CVI optics]
par.omcOptics(3).diameter      = 0.0254;      % m (1")                     [T1000276]
par.omcOptics(3).thickness     = 0.00635;     % m (1/4", at max)           [Guess from T1000276] ("It's either 3/8" or 1/4" " -- Nic Smith)
par.omcOptics(3).mass          = 0.00787;     % kg                         [Calc'd, using 2.2e3 kg m^(-3) for Fused Silica]
par.omcOptics(3).displacement  = 0;           % m (for starters.)
par.omcOptics(3).position      = [0;...       % m (X)                      []
                                  0;...       % m (Y)                    
                                  0];         % m (Z)

% Output Mode Cleaner Mirror 3 (OMCM3)   
par.omcOptics(4).name          = 'OMCM3';
par.omcOptics(4).location      = 'HAM6';
par.omcOptics(4).susType       = 'omcdoubl';
par.omcOptics(4).seiType       = 'hamprcl';   % [] (HAM ISI [No FF L4Cs] + HAM HEPI) 
par.omcOptics(4).surf1.AoI     = 6.0;         % deg                        [T080144]
par.omcOptics(4).surf1.RoC     = inf;         % m                          [T080144]
par.omcOptics(4).surf1.plrztn  = '';          % []                         []
par.omcOptics(4).surf1.rTrans  = 8000e-6;     % [] (in power, @ 1064 nm)   [T1000276]
par.omcOptics(4).surf1.gTrans  = NaN;         % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.omcOptics(4).surf1.loss    = 0;           % [] (in power, @ 1064 nm)   []
par.omcOptics(4).surf2.AoI     = 6.0;         % deg                        [[ CHECKME! ]]
par.omcOptics(4).surf2.RoC     = inf;         % m                          [[ CHECKME! ]]
par.omcOptics(4).surf2.plrztn  = '';          % []                         []
par.omcOptics(4).surf2.rRefl   = 0;           % [] (in power, @ 1064 nm)   []
par.omcOptics(4).surf2.gRefl   = NaN;         % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.omcOptics(4).surf2.loss    = 0;           % [] (in power, @ 1064 nm)   []
par.omcOptics(4).substrateLoss = 2e-7;        % [] (in power, @ 1064 nm)   [Upper Limit, P. Fritschel]
par.omcOptics(4).wedgeAngle    = 0.000;       % deg                        [They're just CVI optics]
par.omcOptics(4).wedgeOrient   = 'None';      % []                         [They're just CVI optics]
par.omcOptics(4).diameter      = 0.0254;      % m (1")                     [T1000276]
par.omcOptics(4).thickness     = 0.00635;     % m (1/4", at max)           [Guess from T1000276] ("It's either 3/8" or 1/4" " -- Nic Smith)
par.omcOptics(4).mass          = 0.00787;     % kg                         [Calc'd, using 2.2e3 kg m^(-3) for Fused Silica]
par.omcOptics(4).displacement  = 0;           % m (for starters.)
par.omcOptics(4).position      = [0;...       % m (X)                      []
                                  0;...       % m (Y)                    
                                  0];         % m (Z)                              
                              
% Output Mode Cleaner Mirror 4 (OMCM4)                          
par.omcOptics(5).name          = 'OMCM4';
par.omcOptics(5).location      = 'HAM6';
par.omcOptics(5).susType       = 'omcdoubl';
par.omcOptics(5).seiType       = 'hamprcl';   % [] (HAM ISI [No FF L4Cs] + HAM HEPI) 
par.omcOptics(5).surf1.AoI     = 6.0;         % deg                        [T080144]
par.omcOptics(5).surf1.RoC     = 2;           % m                          [T080144]
par.omcOptics(5).surf1.plrztn  = '';          % []                         []
par.omcOptics(5).surf1.rTrans  = 30e-6;       % [] (in power, @ 1064 nm)   [mean([H1M2 H1M4]), T080144]
par.omcOptics(5).surf1.gTrans  = NaN;         % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.omcOptics(5).surf1.loss    = 0;           % [] (in power, @ 1064 nm)   []
par.omcOptics(5).surf2.AoI     = 6.0;         % deg                        [[ CHECKME! ]]
par.omcOptics(5).surf2.RoC     = inf;         % m                          [[ CHECKME! ]]
par.omcOptics(5).surf2.plrztn  = '';          % []                         []
par.omcOptics(5).surf2.rRefl   = 0;           % [] (in power, @ 1064 nm)   []
par.omcOptics(5).surf2.gRefl   = NaN;         % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.omcOptics(5).surf2.loss    = 0;           % [] (in power, @ 1064 nm)   []
par.omcOptics(5).substrateLoss = 2e-7;        % [] (in power, @ 1064 nm)   [Upper Limit, P. Fritschel]
par.omcOptics(5).wedgeAngle    = 0.000;       % deg                        [They're just CVI optics]
par.omcOptics(5).wedgeOrient   = 'None';      % []                         [They're just CVI optics]
par.omcOptics(5).diameter      = 0.0254;      % m (1")                     [T1000276]
par.omcOptics(5).thickness     = 0.00635;     % m (1/4", at max)           [Guess from T1000276] ("It's either 3/8" or 1/4" " -- Nic Smith)
par.omcOptics(5).mass          = 0.00787;     % kg                         [Calc'd, using 2.2e3 kg m^(-3) for Fused Silica]
par.omcOptics(5).displacement  = 0;           % m (for starters.)
par.omcOptics(5).position      = [0;...       % m (X)                      []
                                  0;...       % m (Y)                    
                                  0];         % m (Z)
                          
% OMC DC PD Beam Spliter (OMCOBS)
par.omcOptics(6).name          = 'OMCOBS';
par.omcOptics(6).location      = 'HAM6';
par.omcOptics(6).susType       = 'omcdoubl';
par.omcOptics(6).seiType       = 'hamprcl';   % [] (HAM ISI [No FF L4Cs] + HAM HEPI) 
par.omcOptics(6).surf1.AoI     = 45.0;        % deg                        [T080144]
par.omcOptics(6).surf1.RoC     = inf;         % m                          [T080144]
par.omcOptics(6).surf1.plrztn  = '';          % []                         []
par.omcOptics(6).surf1.rTrans  = 0.5;         % [] (in power, @ 1064 nm)   []
par.omcOptics(6).surf1.gTrans  = NaN;         % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.omcOptics(6).surf1.loss    = 0;           % [] (in power, @ 1064 nm)   []
par.omcOptics(6).surf2.AoI     = 45.0;        % deg                        [T080144]
par.omcOptics(6).surf2.RoC     = inf;         % m                          [T080144]
par.omcOptics(6).surf2.plrztn  = '';          % []                         []
par.omcOptics(6).surf2.rRefl   = 0;           % [] (in power, @ 1064 nm)   []
par.omcOptics(6).surf2.gRefl   = NaN;         % [] (in power, @ 532 nm)    [Not Spec'd, No Need]
par.omcOptics(6).surf2.loss    = 0;           % [] (in power, @ 1064 nm)   []
par.omcOptics(6).substrateLoss = 2e-7;        % [] (in power, @ 1064 nm)   [Upper Limit, P. Fritschel]
par.omcOptics(6).wedgeAngle    = 0.000;       % deg                        [They're just CVI optics]
par.omcOptics(6).wedgeOrient   = 'None';      % []                         [They're just CVI optics]
par.omcOptics(6).diameter      = 0.0254;      % m (1")                     [T1000276]
par.omcOptics(6).thickness     = 0.00635;     % m (1/4", at max)           [Guess from T1000276] ("It's either 3/8" or 1/4" " -- Nic Smith)
par.omcOptics(6).mass          = 0.00787;     % kg                         [Calc'd, using 2.2e3 kg m^(-3) for Fused Silica]
par.omcOptics(6).displacement  = 0;           % m (for starters.)
par.omcOptics(6).position      = [0;...       % m (X)                      []
                                  0;...       % m (Y)                    
                                  0];         % m (Z)                              
                                
%% 8 %% Other Sensor Path Optics %% %%
%%%%%   | Property       | Value        | Units (notes)                    | Reference    %%%%% 

% REFL Telescope
% Block Diagram D1000342

% POP Telescope
% Block Diagram D1000342

% END TRANSMON Telescope
% Block Diagram D1000484

% par.auxOptics(1).name           = 'TRXM1';
% par.auxOptics(1).location       = 'BSC9';
% par.auxOptics(1).susType        = 'transmon';
% par.auxOptics(1).seiType        = 'bschepi';
% par.auxOptics(1).surf1.AoI      = 0;           % deg                       []
% par.auxOptics(1).surf1.RoC      = 0;           % m                         []
% par.auxOptics(1).surf1.plrztn   = '';          % []
% par.auxOptics(1).surf1.rTrans   = 0;           % [] (in power, @ 1064 nm)  []
% par.auxOptics(1).surf1.gTrans   = 0;           % [] (in power, @ 532 nm)   []
% par.auxOptics(1).surf1.loss     = 0;           % deg                       []
% par.auxOptics(1).surf2.AoI      = 0;           % [] (in power, @ 1064 nm)  []
% par.auxOptics(1).surf2.RoC      = 0;           % m                         []
% par.auxOptics(1).surf2.rTrans   = 0;           % [] (in power, @ 1064 nm)  []
% par.auxOptics(1).surf2.gTrans   = 0;           % [] (in power, @ 532 nm)   []
% par.auxOptics(1).surf2.loss     = 0;           % [] (in power, @ 1064 nm)  []
% par.auxOptics(1).substrateLoss  = 0;           % [] (in power, @ 1064 nm)  []
% par.auxOptics(1).wedgeAngle     = 0;           % deg                       []
% par.auxOptics(1).wedgeOrient    = 0;           %                           []
% par.auxOptics(1).diameter       = 0;           % m                         []
% par.auxOptics(1).thickness      = 0;           % m (at max)                []
% par.auxOptics(1).mass           = 0;           % kg                        []
% par.auxOptics(1).position       = [0;...       % m (X)                     []
%                                   0;...       % m (Y)                    
%                                   0];         % m (Z) 
% 
% par.auxOptics(2).name           = 'TRXM2';
% par.auxOptics(2).location       = 'BSC9';
% par.auxOptics(2).susType        = 'transmon';
% par.auxOptics(2).seiType        = 'bschepi';
% par.auxOptics(2).surf1.AoI      = 0;           % deg                       []
% par.auxOptics(2).surf1.RoC      = 0;           % m                         []
% par.auxOptics(2).surf1.plrztn   = '';          % []
% par.auxOptics(2).surf1.rTrans   = 0;           % [] (in power, @ 1064 nm)  []
% par.auxOptics(2).surf1.gTrans   = 0;           % [] (in power, @ 532 nm)   []
% par.auxOptics(2).surf1.loss     = 0;           % deg                       []
% par.auxOptics(2).surf2.AoI      = 0;           % [] (in power, @ 1064 nm)  []
% par.auxOptics(2).surf2.RoC      = 0;           % m                         []
% par.auxOptics(2).surf2.rTrans   = 0;           % [] (in power, @ 1064 nm)  []
% par.auxOptics(2).surf2.gTrans   = 0;           % [] (in power, @ 532 nm)   []
% par.auxOptics(2).surf2.loss     = 0;           % [] (in power, @ 1064 nm)  []
% par.auxOptics(2).substrateLoss  = 0;           % [] (in power, @ 1064 nm)  []
% par.auxOptics(2).wedgeAngle     = 0;           % deg                       []
% par.auxOptics(2).wedgeOrient    = 0;           %                           []
% par.auxOptics(2).diameter       = 0;           % m                         []
% par.auxOptics(2).thickness      = 0;           % m (at max)                []
% par.auxOptics(2).mass           = 0;           % kg                        []
% par.auxOptics(2).position       = [0;...       % m (X)                     []
%                                   0;...       % m (Y)                    
%                                   0];         % m (Z) 

% % Empty Optic Structure
% par.o.name          = '';
% par.o.susType       = '';   % [] ()
% par.o.seiType       = '';   % [] ()
% par.o.surf1.AoI     = 0;    % deg                      []
% par.o.surf1.RoC     = 0;    % m                        []
% par.o.surf1.plrztn  = '';   % []                       []
% par.o.surf1.rTrans  = 0;    % [] (in power, @ 1064 nm) []
% par.o.surf1.gTrans  = 0;    % [] (in power, @ 532 nm)  []
% par.o.surf1.loss    = 0;    % [] (in power, @ 1064 nm) []
% par.o.surf2.AoI     = 0;    % deg                      []
% par.o.surf2.RoC     = 0;    % m                        []
% par.o.surf2.rRefl   = 0;    % [] (in power, @ 1064 nm) []
% par.o.surf2.gRefl   = 0;    % [] (in power, @ 532 nm)  []
% par.o.surf2.loss    = 0;    % [] (in power, @ 1064 nm) []
% par.o.substrateLoss = 0;    % [] (in power, @ 1064 nm) []
% par.o.wedgeAngle    = 0;    % deg                      []
% par.o.wedgeOrient   = '';   % [] (Thick)               []
% par.o.diameter      = 0;    % m                        []
% par.o.thickness     = 0;    % m (at max)               []
% par.o.mass          = 0;    % kg                       []
% par.o.position      = [0;...% m (X)                    []
%                        0;...% m (Y)                    
%                        0];  % m (Z)

%% 9 %% Detector Geometry %% %%
% All values taken to be for a "straight" interferometer.
% All values from Closest Surface to Closest Surface as the beam flies,
% e.g. BStoCPX is from the AR surface (surface 2) of the BS to the
% "near/inside" AR surface of the CPX, but BStoCPY is from the BS HR
% surface to the "near/inside" AR surface of CPY. All effective optical
% path lengths through transmissive optics are added in the "opt" file when
% building links between optics (though they are computed below). 
%
% CAUTION: some of these numbers have been updated
% to match E1101146 and E1101147
%

%%%|Property              | Value         | Units (notes)                  | Reference    %%%%%
par.lengths.schnuppAssy   =    0.0504;    % m                              | [3]
par.lengths.thinCpCorxn   =    0.0150;    % m (1/2 of 3cm from ea. side)   | [T1000175]

% Defined Parameters
par.lengths.PRMtoPR2      =   16.6037;    % m                              | [3, Table 1]
par.lengths.PR2toPR3      =   16.1558;    % m                              | [3, Table 1]
par.lengths.PR3toBS       =   19.5384;    % m                              | [3, Table 1]
par.lengths.BStoCPX       =    4.8046 + par.lengths.thinCpCorxn; % m       | [3, Table 1 + T1000175] 
par.lengths.CPXtoITMX     =    0.0050 + par.lengths.thinCpCorxn; % m       | [3, Table 1 + T1000175] 
par.lengths.BStoCPY       =    4.8497 + par.lengths.thinCpCorxn; % m       | [3, Table 1 + T1000175] 
par.lengths.CPYtoITMY     =    0.0050 + par.lengths.thinCpCorxn; % m       | [3, Table 1 + T1000175] 
par.lengths.ITMXtoETMX    = 3994.5000;    % m                              | [3]
par.lengths.ITMYtoETMY    = 3994.5000;    % m                              | [3]
par.lengths.ETMXtoERMX    =    0.0050;    % m                              | [D0901346]
par.lengths.ETMYtoERMY    =    0.0050;    % m                              | [D0901346]
par.lengths.BStoSR3       =   19.3680;    % m                              | [3, Table 1]
par.lengths.SR3toSR2      =   15.4067;    % m                              | [3, Table 1]
par.lengths.SR2toSRM      =   15.7260;    % m                              | [3, Table 1]
par.lengths.SRMtoOMMT1    =    3.6460;    % m                              | [T1000317]
par.lengths.OMMT1toOMMT2  =    1.3950;    % m                              | [T1000317]
par.lengths.OMMT2toOMMT3  =    0.7080;    % m                              | [T1000317]       
par.lengths.OMMT3toOMCSM  =    0.2680;    % m                              | [T1000317]
par.lengths.OMCSMtoOMCM1  =    0.0560;    % m (includes OMCM1 thickness)   | [T080144]
par.lengths.OMCM1toOMCM2  =    0.2710;    % m                              | [T080144]
par.lengths.OMCM2toOMCM3  =    0.2750;    % m                              | [T080144]
par.lengths.OMCM3toOMCM4  =    0.2840;    % m                              | [T080144]
par.lengths.OMCM4toOMCM1  =    0.2660;    % m (includes OMCM4 thickness)   | [T080144]
par.lengths.OMCM4toOMCOBS =    0.1180;    % m                              | [T080144]
par.lengths.OMCOBStoDCPD1 =    0.0610;    % m                              | [T080144]
par.lengths.OMCOBStoDCPD2 =    0.0380;    % m (includes OMCOBS thickness)  | [T080144]

% Optical Path Lengths
% Non-normal incidence optics
par.lengths.MC1ARtoMC1HR    = par.constants.n_FS * ...                     % m [T1100030]
                               ((par.inOptics(1).thickness - (par.inOptics(1).diameter/2) ...
                               *tan(par.inOptics(1).wedgeAngle))*cos(par.inOptics(1).wedgeAngle)) ...
                               / (cos(asin((par.constants.n_V/par.constants.n_FS) ...
                               *sin(par.inOptics(1).surf2.AoI))));
                           
par.lengths.MC3HRtoMC3AR    = par.constants.n_FS * ...                     % m [T1100030]
                               ((par.inOptics(1).thickness - (par.inOptics(1).diameter/2) ...
                               *tan(par.inOptics(1).wedgeAngle))*cos(par.inOptics(1).wedgeAngle)) ...
                               / (cos(par.inOptics(1).wedgeAngle ...
                               - asin((par.constants.n_V/par.constants.n_FS) ...
                               *sin(par.inOptics(1).surf1.AoI))));
                           

par.lengths.PR2HRtoPR2AR   = par.constants.n_FS*par.coreOptics(2).thickness; % m [[FIX ME!!]]

par.lengths.BSHRtoBSAR     = par.constants.n_FS*par.coreOptics(4).thickness ...     % m
                              / cos(asin((par.constants.n_V/par.constants.n_FS) ...
                             *sin(180/pi*par.coreOptics(4).surf1.AoI)));
                      
% Normal incidence       
par.lengths.PRMARtoPRMHR   = par.constants.n_FS*par.coreOptics(1).thickness;   % m
par.lengths.CPXARtoCPXAR   = par.constants.n_FS*par.coreOptics(5).thickness;   % m
par.lengths.ITMXARtoITMXHR = par.constants.n_FS*par.coreOptics(6).thickness;   % m
par.lengths.ETMXHRtoEMTXAR = par.constants.n_FS*par.coreOptics(7).thickness;   % m
par.lengths.ERMXARtoERMXAR = par.constants.n_FS*par.coreOptics(8).thickness;   % m
par.lengths.CPYARtoCPYAR   = par.constants.n_FS*par.coreOptics(9).thickness;   % m 
par.lengths.ITMYARtoITMYHR = par.constants.n_FS*par.coreOptics(10).thickness;  % m
par.lengths.ETMYHRtoETMYAR = par.constants.n_FS*par.coreOptics(11).thickness;  % m
par.lengths.ERMYARtoERMYAR = par.constants.n_FS*par.coreOptics(12).thickness;  % m
par.lengths.SRMHRtoSRMAR   = par.constants.n_FS*par.coreOptics(15).thickness;  % m

% DARM = L.x - L.y
% CARM = L.x + L.y
% MICH = l.x - l.y
% PRCL = l.p + (l.x + l.y)/2
% SRCL = l.s + (l.x + l.y)/2

% Cavity Lengths
par.lengths.Lx    = par.lengths.ITMXtoETMX;              % m

par.lengths.Ly    = par.lengths.ITMYtoETMY;              % m                                             

par.lengths.lx    = par.lengths.BSHRtoBSAR ...
                    + par.lengths.BStoCPX ...
                      + par.lengths.CPXARtoCPXAR ...
                        + par.lengths.CPXtoITMX ...   
                          + par.lengths.ITMXARtoITMXHR;  % m
                         
par.lengths.ly    = par.lengths.BStoCPY ...
                    + par.lengths.CPYARtoCPYAR ...
                      + par.lengths.CPYtoITMY ...
                        + par.lengths.ITMYARtoITMYHR;    % m
                    
par.lengths.lmean = (par.lengths.lx + par.lengths.ly)/2; % m                    
                       
par.lengths.lp    = par.lengths.PRMtoPR2 ...
                    + par.lengths.PR2toPR3 ...
                      + par.lengths.PR3toBS;             % m
                  
par.lengths.lprc  = par.lengths.lp + par.lengths.lmean;  % m                  

par.lengths.ls    = par.lengths.BSHRtoBSAR ...
                    + par.lengths.BStoSR3 ...
                      + par.lengths.SR3toSR2 ...
                        + par.lengths.SR2toSRM;          % m
                    
par.lengths.lsrc  = par.lengths.ls + par.lengths.lmean;  % m
                    
par.lengths.lout  = par.lengths.SRMtoOMMT1 ...
                    + par.lengths.OMMT1toOMMT2 ...
                      + par.lengths.OMMT2toOMMT3 ...
                        + par.lengths.OMMT3toOMCSM;          % m
                       
par.lengths.lomc  = par.lengths.OMCM1toOMCM2 ...         (WARNING: aLIGO OMC is 0.714 m [T1000276],
                    + par.lengths.OMCM2toOMCM3 ...        this yields eLIGO H1 length of
                      + par.lengths.OMCM3toOMCM4 ...      1.096 m, from T080144)
                        + par.lengths.OMCM4toOMCM1;      % m

% par.lengths.ls         = 50.555;      % m (SRMtoSR2+SR2toSR3+SR3toBS)    [3] 
% par.lengths.lx         = 4.8096;      % m (BStoCPX+CPXtoIX)              [3] [[ CHECKME! ]]
% par.lengths.ly         = 4.8467;      % m (BStoCPY+CPYtoIY)              [D0901920]
% par.lengths.lprc       = 57.6557;     % m                                [2]
% par.lengths.lsrc       = 56.0084;     % m
% par.lengths.limc       = 32.9461      % m (MC1toMC2+MC2toMC3+MC3toMC1)   [2]                               
% par.lengths.lomc       = 0.714;       % m (M1toM2+M2toM3+M3toM4+M4toM1)  [7]


% Input Optics
par.lengths.LasertoAM    = 0;                                              % m [[FIXME!!]]
par.lengths.AMtoPM       = 0;                                              % m [[FIXME!!]]
par.lengths.PMtoEOM1     = 1;                                              % m [[FIXME!!]]
par.lengths.EOM1toEOM2   = 1;                                              % m [[FIXME!!]]
par.lengths.EOM2toMC1    = 20;                                             % m [[FIXME!!]]

par.lengths.MC3toMC1     = sqrt((par.inOptics(1).position(1) ...           % m [D0901920, but FIXME!!]
                                    - par.inOptics(3).position(1)).^2 + ...
                                (par.inOptics(1).position(2) ...
                                    - par.inOptics(3).position(2)).^2 + ...
                                (par.inOptics(1).position(3) ...
                                    - par.inOptics(3).position(3)).^2); 

par.lengths.MC1toMC2     = (par.lengths.MC3toMC1)/(2*cos(2*par.inOptics(1).surf1.AoI*(pi/180)));
                                
par.lengths.MC2toMC3     = (par.lengths.MC3toMC1)/(2*cos(2*par.inOptics(3).surf1.AoI*(pi/180)));                         

par.lengths.limc         = par.lengths.MC1toMC2 ...
                           + par.lengths.MC2toMC3 ...
                             + par.lengths.MC3toMC1;       % m (MC1toMC2+MC2toMC3+MC3toMC1)   [2 says 32.9461 m, this yields 32.957] 
                                
par.lengths.MC3toSM1     = sqrt((par.inOptics(4).position(1) ...           % m [D0901920, but FIXME!!]
                                    - par.inOptics(3).position(1)).^2 + ...
                                (par.inOptics(4).position(2) ...
                                    - par.inOptics(3).position(2)).^2 + ...
                                (par.inOptics(4).position(3) ...
                                    - par.inOptics(3).position(3)).^2);                                 

par.lengths.SM1toPMMT1   = sqrt((par.inOptics(5).position(1) ...           % m [D0901920, but FIXME!!]
                                    - par.inOptics(4).position(1)).^2 + ...
                                (par.inOptics(5).position(2) ...
                                    - par.inOptics(4).position(2)).^2 + ...
                                (par.inOptics(5).position(3) ...
                                    - par.inOptics(4).position(3)).^2);

par.lengths.PMMT1toPMMT2 = sqrt((par.inOptics(7).position(1) ...           % m [D0901920, but FIXME!!]
                                    - par.inOptics(5).position(1)).^2 + ...
                                (par.inOptics(7).position(2) ...
                                    - par.inOptics(5).position(2)).^2 + ...
                                (par.inOptics(7).position(3) ...
                                    - par.inOptics(5).position(3)).^2);

par.lengths.PMMT2toSM2   = sqrt((par.inOptics(8).position(1) ...           % m [D0901920, but FIXME!!]
                                    - par.inOptics(7).position(1)).^2 + ...
                                (par.inOptics(8).position(2) ...
                                    - par.inOptics(7).position(2)).^2 + ...
                                (par.inOptics(8).position(3) ...
                                    - par.inOptics(7).position(3)).^2); 
                            
par.lengths.SM2toPRM     = sqrt((par.coreOptics(1).position(1) ...         % m [D0901920, but FIXME!!]
                                    - par.inOptics(8).position(1)).^2 + ...
                                (par.coreOptics(1).position(2) ...
                                    - par.inOptics(8).position(2)).^2 + ...
                                (par.coreOptics(1).position(3) ...
                                    - par.inOptics(8).position(3)).^2);                 

                                
                                
%% 10 %% Seismic Isolation %% %%

% seiDir = [cvsDir '/LentickleAligo/SeismicIsolation/'];
% 
% sw = warning;
% warning('OFF', 'Control:ltiobject:UpdatePreviousVersion')
% 
% quad = load([seiDir 'QUAD_Model.mat']);
% bsfm = load([seiDir 'BSFM_Model.mat']);
% hlts = load([seiDir 'HLTS_Model.mat']);
% hsts = load([seiDir 'HSTS_Model.mat']);
% omcd = load([seiDir 'OMCD_Model.mat']);
% 
% warning(sw)
% 
% % HAM Aux Single
% haux.f0           = 0.98;                                         % Hz     [[FIXME!!]] [Guess from T1000339]
% haux.Q            = 40;                                           % []     [[FIXME!!]] [Guess from T1000339]
% haux.susMass      = 0.3738;                                       % kg     [T1000339]
% haux.optoMech.zpk = zpk([],-rootsFQ(haux.f0, haux.Q),1/haux.susMass);
% 
% % OMMT Single (Tip-Tilts)
% ommt.f0           = 1.0;                                          % Hz     [[FIXME!!]]
% ommt.Q            = 20;                                           % []     [[FIXME!!]] 
% ommt.susMass      = 0.042;                                        % kg     [[FIXME!!]]
% ommt.optoMech.zpk = zpk([],-rootsFQ(ommt.f0,ommt.Q),1/ommt.susMass);
% 
% % OMC Double Bench
% % --- assume that optics on the bench just don't move.
% omcd.optoMech.zpk = zpk([],[],0);
% 
% % par.seiIsoTFs.bschepi
% % par.seiIsoTFs.hamhepi
% % 
% % par.seiIsoTFs.bscisi
% % par.seiIsoTFs.prclisi 
% % par.seiIsoTFs.srclisi
% 
% par.seiIsoTFs.freq     = quad.freq;
% par.seiIsoTFs.hauxsngl = squeeze(freqresp(haux.optoMech.zpk,2*pi*par.seiIsoTFs.freq));
% par.seiIsoTFs.ommtsngl = squeeze(freqresp(ommt.optoMech.zpk,2*pi*par.seiIsoTFs.freq));
% par.seiIsoTFs.omcdoubl = squeeze(omcd.OMCD_freqresp(omcd.out.long_bot,omcd.in.long_gnd,:));
% par.seiIsoTFs.hststrpl = squeeze(hsts.HSTS_freqresp(hsts.out.long_bot,hsts.in.long_gnd,:));
% par.seiIsoTFs.hltstrpl = squeeze(hlts.HLTS_freqresp(hlts.out.long_bot,hlts.in.long_gnd,:));
% par.seiIsoTFs.bsfmtrpl = squeeze(bsfm.BSFM_freqresp(bsfm.out.long_bot,bsfm.in.long_gnd,:));
% par.seiIsoTFs.wirequad = squeeze(quad.QUAD_freqresp(quad.out.long_tm,quad.in.long_gnd,:));
% par.seiIsoTFs.monoquad = squeeze(quad.QUAD_freqresp(quad.out.long_tm,quad.in.long_gnd,:));
% 
% par.optoMechTFs.freq     = quad.freq;
% par.optoMechTFs.hauxsngl = squeeze(freqresp(haux.optoMech.zpk,2*pi*par.optoMechTFs.freq));
% par.optoMechTFs.ommtsngl = squeeze(freqresp(ommt.optoMech.zpk,2*pi*par.optoMechTFs.freq));
% par.optoMechTFs.omcdoubl = squeeze(freqresp(omcd.optoMech.zpk,2*pi*par.optoMechTFs.freq));
% par.optoMechTFs.hststrpl = squeeze(hsts.HSTS_freqresp(hsts.out.long_bot,hsts.in.long_bot_drive,:));
% par.optoMechTFs.hltstrpl = squeeze(hlts.HLTS_freqresp(hlts.out.long_bot,hlts.in.long_bot_drive,:));
% par.optoMechTFs.bsfmtrpl = squeeze(bsfm.BSFM_freqresp(bsfm.out.long_bot,bsfm.in.long_bot_drive,:));
% par.optoMechTFs.wirequad = squeeze(quad.QUAD_freqresp(quad.out.long_tm,quad.in.long_tm_drive,:));
% par.optoMechTFs.monoquad = squeeze(quad.QUAD_freqresp(quad.out.long_tm,quad.in.long_tm_drive,:));

end

% 
% r = rootsFQ(f0, Q)
%
% f0 and Q are the resonance frequency and quaity factor
% r is the corresponding pair of roots (i.e., zeros or poles)
%
% if Q == 0, a real root is assumed (i.e., r = 2 * pi * f0)

function r = rootsFQ(f0, Q)

  r0 = 2 * pi * f0;
  nc = find(Q ~= 0);

  res = sqrt(1 - 4 * Q(nc).^2);
  mag = r0(nc) ./ (2 * Q(nc));
  r0(nc) = mag .* (1 + res);
  r = [r0; mag .* (1 - res)];
end