% Simple Sagnac Speedmeter configuration, based on Optocad model 1.1b.
%
% Script layout based on work by Tobin Fricke and Matt Evans.
%
% Sean Leavey
% October 2014
function opt = optSagnacSpeedmeterA(par)

%% Create Optickle model
% frequencies to model are specified in parameters
opt = Optickle(par.laser.vFrf);

%% Add fields

% add a source, with RF amplitudes specified
opt.addSource('Laser', par.laser.vArf);

% add modulators for Laser amplitude and phase noise
opt.addModulator('AM', 1);
opt.addModulator('PM', 1i);

% link, output of Laser is PM->out
opt.addLink('Laser', 'out', 'AM', 'in', 0);
opt.addLink('AM', 'out', 'PM', 'in', 0);

%% Add RF modulator

% EOM
opt.addRFmodulator('Mod', par.mod.f, 1i * par.mod.gamma);

% link from laser
opt.addLink('PM', 'out', 'Mod', 'in', 0);

%% Add optics

% The argument list for addMirror is:
% [opt, sn] = addMirror(opt, name, aio, Chr, Thr, Lhr, Rar, Lmd)
% type "help addMirror" for more information

listBeamSplitter = { ...
     'M1a', 'M1b', 'M2a', 'M2b', 'M3a', 'M3b', 'M6', 'M7', 'M8', 'M9', 'M10', 'M11', 'M16' ...
};

listMirror = { ...
    'M4', 'M5', ...
    'M12', 'M13', 'M14', 'M15' ...
};

for n = 1 : length(listBeamSplitter)
    name = listBeamSplitter{n};
    p = par.(name);
    
    opt.addBeamSplitter(name, p.AngleOfIncidence, 1 / p.Curvature, p.TransmissivityHR, p.LossHR, p.ReflectivityAR, p.LossMd);
end

for n = 1 : length(listMirror)
    name = listMirror{n};
    p = par.(name);
    
    % all normal mirrors (i.e. not beam splitters) are infinitely thin
    opt.addMirror(name, p.AngleOfIncidence, 1 / p.Curvature, p.TransmissivityHR, p.LossHR, p.ReflectivityAR, p.LossMd);
end

%% Set optic mechanical transfer functions

% longitudinal

% % pitch
% no pitch TFs yet

%% Add sinks for photodiodes

% for laser stabilisation
opt.addSink('LaserStab');

%% Add links

% RF modulator -> M4
opt.addLink('Mod', 'out', 'M4', 'fr', par.lengths.ModtoM4);

% M4 -> M5
opt.addLink('M4', 'fr', 'M5', 'fr', par.lengths.M4toM5);

% M5 -> M11
opt.addLink('M5', 'fr', 'M11', 'frB', par.lengths.M5toM11);

% M11 -> M6
opt.addLink('M11', 'frB', 'M6', 'bkB', par.lengths.M11toM6);
opt.addLink('M6', 'bkA', 'M11', 'frA', par.lengths.M11toM6);

% M6 -> M7
opt.addLink('M6', 'frB', 'M7', 'frA', par.lengths.M6toM7);
opt.addLink('M7', 'frB', 'M6', 'frA', par.lengths.M6toM7);

% M7 -> M1a
opt.addLink('M7', 'frA', 'M1a', 'bkA', par.lengths.M7toM1a);
opt.addLink('M1a', 'bkB', 'M7', 'frB', par.lengths.M7toM1a);

% M1a -> M2a
opt.addLink('M1a', 'frA', 'M2a', 'frA', par.lengths.M1atoM2a);
opt.addLink('M2a', 'frB', 'M1a', 'frB', par.lengths.M1atoM2a);

% M2a -> M3a
opt.addLink('M2a', 'frA', 'M3a', 'frA', par.lengths.M2atoM3a);
opt.addLink('M3a', 'frB', 'M2a', 'frB', par.lengths.M2atoM3a);

% M3a -> M1a
opt.addLink('M3a', 'frA', 'M1a', 'frA', par.lengths.M3atoM1a);
opt.addLink('M1a', 'frB', 'M3a', 'frB', par.lengths.M3atoM1a);

% M11 -> LaserStab
opt.addLink('M11', 'bkB', 'LaserStab', 'in', par.lengths.M11toLaserStab);

% M6 -> M1b
opt.addLink('M6', 'bkB', 'M1b', 'bkA', par.lengths.M6toM1b);
opt.addLink('M1b', 'bkB', 'M6', 'bkA', par.lengths.M6toM1b);

% M1b -> M2b
opt.addLink('M1b', 'frA', 'M2b', 'frA', par.lengths.M1btoM2b);
opt.addLink('M2b', 'frB', 'M1b', 'frB', par.lengths.M1btoM2b);

% M2b -> M3b
opt.addLink('M2b', 'frA', 'M3b', 'frA', par.lengths.M2btoM3b);
opt.addLink('M3b', 'frB', 'M2b', 'frB', par.lengths.M2btoM3b);

% M3b -> M1b
opt.addLink('M3b', 'frA', 'M1b', 'frA', par.lengths.M3btoM1b);
opt.addLink('M1b', 'frB', 'M3b', 'frB', par.lengths.M3btoM1b);

% M1a -> M10
opt.addLink('M1a', 'bkA', 'M10', 'frB', par.lengths.M1atoM10);
opt.addLink('M10', 'frA', 'M1a', 'bkB', par.lengths.M1atoM10);

% M10 -> M9
opt.addLink('M10', 'frB', 'M9', 'frB', par.lengths.M10toM9);
opt.addLink('M9', 'frA', 'M10', 'frA', par.lengths.M10toM9);

% M9 -> M8
opt.addLink('M9', 'frB', 'M8', 'frA', par.lengths.M9toM8);
opt.addLink('M8', 'frB', 'M9', 'frA', par.lengths.M9toM8);

% M8 -> M1b
opt.addLink('M8', 'frA', 'M1b', 'bkB', par.lengths.M8toM1b);
opt.addLink('M1b', 'bkA', 'M8', 'frB', par.lengths.M8toM1b);

% M11 -> M12
opt.addLink('M11', 'bkA', 'M12', 'fr', par.lengths.M11toM12);

% M12 -> M13
opt.addLink('M12', 'fr', 'M13', 'fr', par.lengths.M12toM13);

% M13 -> M16
opt.addLink('M13', 'fr', 'M16', 'bkB', par.lengths.M13toM16);

% M6 -> M14
opt.addLink('M6', 'frA', 'M14', 'fr', par.lengths.M6toM14);

% M14 -> M15
opt.addLink('M14', 'fr', 'M15', 'fr', par.lengths.M14toM15);

%% Suspensions

% set some mechanical transfer functions
w = 2 * pi * 0.8;      % pendulum resonance frequency

dampRes = [0.001 + 1i, 0.001 - 1i];

opt.setMechTF('M1a', zpk([], -w * dampRes, 0 / 1.6e-3));
opt.setMechTF('M1b', zpk([], -w * dampRes, 0 / 1.6e-3));

%% Homodyne
nCarrier = find(par.laser.vFrf == 0, 1);
opt.addHomodyne('HD', opt.nu(nCarrier), Optickle.polS, 90, 1, 'M15', 'fr');

% set output matrix for homodyne readout
nHDA_DC = opt.getProbeNum('HDA_DC');
nHDB_DC = opt.getProbeNum('HDB_DC');

opt.mProbeOut = eye(opt.Nprobe);      % start with identity matrix
opt.mProbeOut(nHDA_DC, nHDB_DC) = 1;  % add B to A
opt.mProbeOut(nHDB_DC, nHDA_DC) = -1; % subtract A from B

end