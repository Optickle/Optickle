% par = parSagnacSpeedmeterA()

function par = parSagnacSpeedmeterA()

%% Constants
par.const.hbar = 1.05457173e-34;       % Planck constant
par.const.clight = 299792458;          % Vacuum speed of light

%% Material properties
par.const.n_silica = 1.44963098985906; % refractive index of silica

%% Laser source
par.const.lambda = 1064e-9;            % Fundamental laser wavelength
par.const.Pin = 1;

%% Modulation
par.mod.f = 15e6;
par.mod.gamma = 0.3;
par.mod.n = 2;

%% Optics

% Mirrors
par.M1a.AngleOfIncidence  = -4.400;
par.M1a.Curvature  = 1 / -7.91;
par.M1a.TransmissivityHR  = 500e-6;
par.M1a.LossHR  = 0;
par.M1a.ReflectivityAR  = 0;
par.M1a.LossMd  = 0;
par.M1a.RefractiveIndex  = par.const.n_silica;

par.M1b.AngleOfIncidence  = par.M1a.AngleOfIncidence;
par.M1b.Curvature  = par.M1a.Curvature;
par.M1b.TransmissivityHR  = par.M1a.TransmissivityHR;
par.M1b.LossHR  = par.M1a.LossHR;
par.M1b.ReflectivityAR  = par.M1a.ReflectivityAR;
par.M1b.LossMd  = par.M1a.LossMd;
par.M1b.RefractiveIndex  = par.M1a.RefractiveIndex;

par.M2a.AngleOfIncidence = 42.80;
par.M2a.Curvature = 0;
par.M2a.TransmissivityHR = 2e-6;
par.M2a.LossHR = 0;
par.M2a.ReflectivityAR = 0;
par.M2a.LossMd = 0;
par.M2a.RefractiveIndex = par.const.n_silica;

par.M2b.AngleOfIncidence = par.M2a.AngleOfIncidence;
par.M2b.Curvature = par.M2a.Curvature;
par.M2b.TransmissivityHR = par.M2a.TransmissivityHR;
par.M2b.LossHR = par.M2a.LossHR;
par.M2b.ReflectivityAR = par.M2a.ReflectivityAR;
par.M2b.LossMd = par.M2a.LossMd;
par.M2b.RefractiveIndex = par.M2a.RefractiveIndex;

par.M3a.AngleOfIncidence = par.M2a.AngleOfIncidence;
par.M3a.Curvature = par.M2a.Curvature;
par.M3a.TransmissivityHR = par.M2a.TransmissivityHR;
par.M3a.LossHR = par.M2a.LossHR;
par.M3a.ReflectivityAR = par.M2a.ReflectivityAR;
par.M3a.LossMd = par.M2a.LossMd;
par.M3a.RefractiveIndex = par.M2a.RefractiveIndex;

par.M3b.AngleOfIncidence = par.M3a.AngleOfIncidence;
par.M3b.Curvature = par.M3a.Curvature;
par.M3b.TransmissivityHR = par.M3a.TransmissivityHR;
par.M3b.LossHR = par.M3a.LossHR;
par.M3b.ReflectivityAR = par.M3a.ReflectivityAR;
par.M3b.LossMd = par.M3a.LossMd;
par.M3b.RefractiveIndex = par.M3a.RefractiveIndex;

par.M4.AngleOfIncidence  = 45;
par.M4.Curvature         = 0;
par.M4.TransmissivityHR  = 0;
par.M4.LossHR            = 0;
par.M4.ReflectivityAR    = 0;
par.M4.LossMd            = 0;
par.M4.RefractiveIndex   = par.const.n_silica;

par.M5.AngleOfIncidence = -45;
par.M5.Curvature = 0;
par.M5.TransmissivityHR = 0;
par.M5.LossHR = 0;
par.M5.ReflectivityAR = 0;
par.M5.LossMd = 0;
par.M5.RefractiveIndex = par.const.n_silica;

par.M7.AngleOfIncidence = 49.40;
par.M7.Curvature = 0;
par.M7.TransmissivityHR = 0;
par.M7.LossHR = 0;
par.M7.ReflectivityAR = 0;
par.M7.LossMd = 0;
par.M7.RefractiveIndex = par.const.n_silica;

par.M8.AngleOfIncidence = 43.33;
par.M8.Curvature = 0;
par.M8.TransmissivityHR = 0;
par.M8.LossHR = 0;
par.M8.ReflectivityAR = 0;
par.M8.LossMd = 0;
par.M8.RefractiveIndex = par.const.n_silica;

par.M9.AngleOfIncidence = -5.477;
par.M9.Curvature = 0;
par.M9.TransmissivityHR = 0;
par.M9.LossHR = 0;
par.M9.ReflectivityAR = 0;
par.M9.LossMd = 0;
par.M9.RefractiveIndex = par.const.n_silica;

par.M10.AngleOfIncidence = -42.26;
par.M10.Curvature = 0;
par.M10.TransmissivityHR = 0;
par.M10.LossHR = 0;
par.M10.ReflectivityAR = 0;
par.M10.LossMd = 0;
par.M10.RefractiveIndex = par.const.n_silica;

par.M12.AngleOfIncidence = -45;
par.M12.Curvature = 0;
par.M12.TransmissivityHR = 0;
par.M12.LossHR = 0;
par.M12.ReflectivityAR = 0;
par.M12.LossMd = 0;
par.M12.RefractiveIndex = par.const.n_silica;

par.M13.AngleOfIncidence = -45;
par.M13.Curvature = 0;
par.M13.TransmissivityHR = 0;
par.M13.LossHR = 0;
par.M13.ReflectivityAR = 0;
par.M13.LossMd = 0;
par.M13.RefractiveIndex = par.const.n_silica;

par.M14.AngleOfIncidence = 45;
par.M14.Curvature = 0;
par.M14.TransmissivityHR = 0;
par.M14.LossHR = 0;
par.M14.ReflectivityAR = 0;
par.M14.LossMd = 0;
par.M14.RefractiveIndex = par.const.n_silica;

par.M15.AngleOfIncidence = 45;
par.M15.Curvature = 0;
par.M15.TransmissivityHR = 0;
par.M15.LossHR = 0;
par.M15.ReflectivityAR = 0;
par.M15.LossMd = 0;
par.M15.RefractiveIndex = par.const.n_silica;

% Beam splitters
par.M6.AngleOfIncidence = 45;
par.M6.Curvature = 0;
par.M6.TransmissivityHR = 0.5;
par.M6.LossHR = 0;
par.M6.ReflectivityAR = 0;
par.M6.LossMd = 0;
par.M6.RefractiveIndex = par.const.n_silica;

par.M11.AngleOfIncidence = 45;
par.M11.Curvature = 0;
par.M11.TransmissivityHR = 0.5;
par.M11.LossHR = 0;
par.M11.ReflectivityAR = 0;
par.M11.LossMd = 0;
par.M11.RefractiveIndex = par.const.n_silica;

par.M16.AngleOfIncidence  = 45;
par.M16.Curvature  = 0;
par.M16.TransmissivityHR  = 0.5;
par.M16.LossHR  = 0;
par.M16.ReflectivityAR  = 0;
par.M16.LossMd  = 0;
par.M16.RefractiveIndex  = par.const.n_silica;

%% Lengths
% These are copied from the Optocad logs

par.lengths.rs2  = 250.E-3;        % beam start{p} -> M4{p}
par.lengths.rs3  = 166.92366E-3;   % M4{p} -> M5{p}
par.lengths.rs4  = 258.0114E-3;    % M5{p} -> M11{p}
par.lengths.rs5  = 72.09037552E-3; % M11{p} -> M6{s}
par.lengths.rs6  = 29.09626832E-3; % M6{s} -> M6{p}
par.lengths.rs7  = 95.75258782E-3; % M6{p} -> M7{p}
par.lengths.rs8  = 297.0895521E-3; % M7{p} -> M1a{s}
par.lengths.rs9  = 6.358908177E-3; % M1a{s} -> M1a{p}
par.lengths.rs10 = 1.303652574E0;  % M1a{p} -> M2a{p}
par.lengths.rs11 = 200.3507096E-3; % M2a{p} -> M3a{p}
par.lengths.rs12 = 1.303648541E0;  % M3a{p} -> M1a{p}
par.lengths.rs13 = 6.873134249E-3; % M11{p} -> M11{s}
par.lengths.rs14 = 135.3753081E-3; % M11{s} -> LaserStab
par.lengths.rs15 = 51.9886E-3;     % M6{s} -> {p}

par.lengths.rs17 = 365.5666524E-3; % M6{s} -> M1b{s}
par.lengths.rs18 = 6.358906699E-3; % M1b{s} -> M1b{p}
par.lengths.rs19 = 1.303747581E0;  % M1b{p} -> M2b{p}
par.lengths.rs20 = 200.1733896E-3; % M2b{p} -> M3b{p}
par.lengths.rs21 = 1.303745588E0;  % M3b{p} -> M1b{p}

par.lengths.rs23 = 499.2783443E-3; % M1a{s} -> M10{p}
par.lengths.rs24 = 326.5506374E-3; % M10{p} -> M9{p}
par.lengths.rs25 = 261.2520758E-3; % M9{p} -> M8{p}
par.lengths.rs26 = 549.7129644E-3; % M8{p} -> M1b{s}





%par.lengths.rs32 = 46.76550179E-3; % M6{p} -> {p}

%par.lengths.rs34 = 549.7735566E-3; % M1b{s} -> M8{p}
%par.lengths.rs35 = 261.2010967E-3; % M8{p} -> M9{p}
%par.lengths.rs36 = 326.4614815E-3; % M9{p} -> M10{p}
%par.lengths.rs37 = 499.3681216E-3; % M10{p} -> M1a{s}





%par.lengths.rs43 = 365.5627695E-3; % M1b{s} -> M6{s}

par.lengths.rs45 = 75.17947101E-3; % M6{p} -> M14{p}
par.lengths.rs46 = 316.765746E-3;  % M14{p} -> M15{p}
par.lengths.rs47 = 168.8040028E-3; % M15{p} -> M16{s}
par.lengths.rs48 = 6.873252275E-3; % M16{s} -> M16{p}

par.lengths.rs50 = 297.2311392E-3; % M1a{s} -> M7{p}
par.lengths.rs51 = 95.7381258E-3;  % M7{p} -> M6{p}

par.lengths.rs53 = 72.09560087E-3; % M6{s} -> M11{p}
par.lengths.rs54 = 257.7096751E-3; % M11{p} -> M5{p}
par.lengths.rs55 = 166.9115634E-3; % M5{p} -> M4{p}
%par.lengths.rs56
par.lengths.rs57 = 300.1722994E-3; % M4{p} -> left outside
par.lengths.rs58 = 68.24411179E-3; % M6{s} -> {p}

par.lengths.rs60 = 29.87787779E-3; % M6{p} -> {p}

par.lengths.rs62 = 73.41651803E-3; % M11{s} -> M12{p}
par.lengths.rs63 = 90.74503873E-3; % M12{p} -> M13{p}
par.lengths.rs64 = 495.3259003E-3; % M13{p} -> M16{p}

par.lengths.rs66 = 45.31931792E-3; % M16{s} -> PhD4{p}
par.lengths.rs67 = 49.65278092E-3; % M16{p} -> PhD3{p}

%% Detector geometry
par.lengths.ModtoM4        = par.lengths.rs2;
par.lengths.M4toM5         = par.lengths.rs3;
par.lengths.M5toM11        = par.lengths.rs4;
par.lengths.M11toM6        = par.lengths.rs5 + par.lengths.rs6;
par.lengths.M6toM7         = par.lengths.rs7;
par.lengths.M7toM1a        = par.lengths.rs8 + par.lengths.rs9;
par.lengths.M1atoM2a       = par.lengths.rs10;
par.lengths.M2atoM3a       = par.lengths.rs11;
par.lengths.M3atoM1a       = par.lengths.rs12;
par.lengths.M11toLaserStab = par.lengths.rs13 + par.lengths.rs14;
par.lengths.M6toM1b        = par.lengths.rs6 + par.lengths.rs17 + par.lengths.rs18;
par.lengths.M1btoM2b       = par.lengths.rs19;
par.lengths.M2btoM3b       = par.lengths.rs20;
par.lengths.M3btoM1b       = par.lengths.rs21;
par.lengths.M1atoM10       = par.lengths.rs9 + par.lengths.rs23;
par.lengths.M10toM9        = par.lengths.rs24;
par.lengths.M9toM8         = par.lengths.rs25;
par.lengths.M8toM1b        = par.lengths.rs18 + par.lengths.rs26;
par.lengths.M11toM12       = par.lengths.rs13 + par.lengths.rs62;
par.lengths.M12toM13       = par.lengths.rs63;
par.lengths.M13toM16       = par.lengths.rs64 - par.lengths.rs48;
par.lengths.M6toM14        = par.lengths.rs45;
par.lengths.M14toM15       = par.lengths.rs46;
par.lengths.M15toM16       = par.lengths.rs47;
par.lengths.M16toPhD3      = par.lengths.rs48 + par.lengths.rs67;
par.lengths.M16toPhD4      = par.lengths.rs66;

%% DO NOT EDIT BELOW THIS LINE

% Fields to model
% This will eventually contain sidebands
f = par.mod.f;
n = (-par.mod.n : par.mod.n)';
vFrf = unique([n * f]);

nCarrier = find(vFrf == 0, 1);
vArf = zeros(size(vFrf));
vArf(nCarrier) = sqrt(par.const.Pin);

par.laser.vFrf = vFrf;
par.laser.vArf = vArf;
par.laser.power = par.const.Pin;
par.laser.wavelength = par.const.lambda;

end