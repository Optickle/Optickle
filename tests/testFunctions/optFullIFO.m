%--------------- o p t F u ll I F O . m -----------------
% Creates an Optickle model instance of Advanced LIGO
%
% by Matt Evans (2012 March)
%
%--------------------------------------------------------
%
% [Description]
% This function creates an interferomter based on the information
% specified in 'par' structure variable.
% The function adds necessary components such as laser, EOM, mirrors in
% to the model and then links all those components while spcifying the
% distance between the components
%
% Example usage:
%        par = aligoifomodel_straight(cvsDir, 10, 0.2); 
%        opt = optFullIFO(par);
%
%--------------------------------------------------------
% 
% [Notes]
% In the current setting PR3, SR2 and SR3 are omitted for simplicity.
% However PR2 is included as a high reflective beam splitter so that
% the POP2 (light coming from BS to PRM) signal can be obtained.
% 
%--------------------------------------------------------
%
% $Id: optFullIFO.m,v 1.4 2013/08/28 01:35:21 kiwamu Exp $

function opt = optFullIFO()

par = paramFullIFO(25);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add a Field Source

% create an empty model, with frequencies specified
opt = Optickle(par.Laser.vFrf);

% add a source, with RF amplitudes specified
opt = addSource(opt, 'Laser', par.Laser.vArf);

% add modulators for Laser amplitude and phase noise
opt = addModulator(opt, 'AM', 1);
opt = addModulator(opt, 'PM', 1i);

% link, output of Laser is PM->out
opt = addLink(opt, 'Laser', 'out', 'AM', 'in', 0);
opt = addLink(opt, 'AM', 'out', 'PM', 'in', 0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add Input Optics
% The argument list for addMirror is:
% [opt, sn] = addMirror(opt, name, aio, Chr, Thr, Lhr, Rar, Lmd)
% type "help addMirror" for more information


% Modulators
opt = addRFmodulator(opt, 'Mod1', par.Mod.f1, 1i * par.Mod.g1);
opt = addRFmodulator(opt, 'Mod2', par.Mod.f2, 1i * par.Mod.g2);

% link, No MZ
opt = addLink(opt, 'PM', 'out', 'Mod1', 'in', 5);
opt = addLink(opt, 'Mod1', 'out', 'Mod2', 'in',0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add Core Optics
%
% The parameter struct must contain parameters the following
% for each mirror: T, L, Rar, mechTF, pos, RoC, AoI

listMirror = {'PR','SR', 'BS', 'IX', 'IY', ...
  'EX', 'EY', 'PR2', 'OMCa', 'OMCb'};

for n = 1:length(listMirror)
  name = listMirror{n};
  p = par.(name);

  % add mirror or beam-splitter
  if strcmp(name, 'BS') || strcmp('PR2', name)
    opt = addBeamSplitter(opt, name, p.AoI, 1 / p.RoC, p.T, p.L, p.Rar, 0);
  else
    opt = addMirror(opt, name, p.AoI, 1 / p.RoC, p.T, p.L, p.Rar, 0);
  end

  % set mechanical transfer-functions and mirror position offsets
  opt = setPosOffset(opt, name, p.pos);
  
  if ~isempty(p.mechTF)
    opt = setMechTF(opt, name, p.mechTF);
  end
end

% add AS port pick-off
opt = addMirror(opt, 'PO_AS', 0, 0, par.Tomc, 0, 0, 0);

%%%%%%%%%%%%%%%%%%%%
% link Modulators output to PR back input (no input Mode Cleaner)
opt = addLink(opt, 'Mod2', 'out', 'PR', 'bk', 0.2);%35);

% link PR front output -> PR2 A-side fron input
opt = addLink(opt, 'PR', 'fr', 'PR2', 'frA', par.Length.PR_PR2);

% link BS A-side inputs to PR2 A-side and SR front outputs
opt = addLink(opt, 'PR2', 'frA', 'BS', 'frA', par.Length.PR2_BS);
opt = addLink(opt, 'SR', 'fr', 'BS', 'bkA', par.Length.SR);

% link BS A-side outputs to and IX and IY back inputs
opt = addLink(opt, 'BS', 'frA', 'IY', 'bk', par.Length.IY);
opt = addLink(opt, 'BS', 'bkA', 'IX', 'bk', par.Length.IX);

% link BS B-side inputs to and IX and IY back outputs
opt = addLink(opt, 'IY', 'bk', 'BS', 'frB', par.Length.IY);
opt = addLink(opt, 'IX', 'bk', 'BS', 'bkB', par.Length.IX);

% link BS B-side outputs to PR2 B-side and SR front inputs
opt = addLink(opt, 'BS', 'frB', 'PR2', 'frB', par.Length.PR2_BS);
opt = addLink(opt, 'BS', 'bkB', 'SR', 'fr', par.Length.SR);

% link PR2 B-side front output to PR fron input
opt = addLink(opt, 'PR2', 'frB', 'PR', 'fr', par.Length.PR_PR2);

% link the X arm
opt = addLink(opt, 'IX', 'fr', 'EX', 'fr', par.Length.EX);
opt = addLink(opt, 'EX', 'fr', 'IX', 'fr', par.Length.EX);

% link the Y arm
opt = addLink(opt, 'IY', 'fr', 'EY', 'fr', par.Length.EY);
opt = addLink(opt, 'EY', 'fr', 'IY', 'fr', par.Length.EY);

% tell Optickle to use this cavity basis
opt = setCavityBasis(opt, 'IX', 'EX');
opt = setCavityBasis(opt, 'IY', 'EY');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Link OMC
opt = addLink(opt, 'SR', 'bk', 'PO_AS', 'fr', 10);
opt = addLink(opt, 'PO_AS', 'bk', 'OMCa', 'bk', 4);
opt = addLink(opt, 'OMCa', 'fr', 'OMCb', 'fr', 1.2);
opt = addLink(opt, 'OMCb', 'fr', 'OMCa', 'fr', 1.2);

opt = setCavityBasis(opt, 'OMCa', 'OMCb');

opt = probesFullIFO(opt, par);



