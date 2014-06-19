% demoPDH  Show Pound-Drever-Hall error signal vs cavity length sweep

% Construct a model of a Fabry-Perot cavity
opt = optFP;

% Retrieve some drive and probe serial numbers from the Optickle model
nEXdrive = getDriveNum(opt, 'EX', 'pos');
nREFL_Iprobe = getProbeNum(opt, 'REFL_I');
nREFL_Qprobe = getProbeNum(opt, 'REFL_Q');

% Set up the limit of our sweep
pos = zeros(opt.Ndrive, 1);
pos(nEXdrive) = -5e-9; % [meters]

% Do the sweep
[poses, sigDC, fDC] = sweepLinear(opt, pos, -pos, 201);

% compute sigAC at low frequency
[~, ~, sigAC] = tickle(opt, [], 1e-6);
fprintf('sigAC: REFL_I [W / nm] = %g, REFL_Q [W / nm] = %g\n', ...
  getTF(sigAC, nREFL_Iprobe, nEXdrive) / 1e9, ...
  getTF(sigAC, nREFL_Qprobe, nEXdrive) / 1e9);

% estimate slope with sweep data
n1 = 100;
n2 = 102;
dx = 1e9 * (poses(nEXdrive,n2) - poses(nEXdrive,n1));   % in nano-meter
dI = sigDC(nREFL_Iprobe, n2) - sigDC(nREFL_Iprobe, n1);
dQ = sigDC(nREFL_Qprobe, n2) - sigDC(nREFL_Qprobe, n1);
fprintf('sigDC: REFL_I [W / nm] = %g, REFL_Q [W / nm] = %g\n', ...
  dI / dx, dQ / dx);

% Plot the results
subplot(2,1,1);
plot(poses(nEXdrive,:), sigDC(nREFL_Iprobe, :), '-', ...
     poses(nEXdrive,:), sigDC(nREFL_Qprobe, :), '-');
 
legend('REFL I', 'REFL Q');
xlabel('cavity detuning [meters]');
ylabel('signal [Watts]');
title('Pound-Drever-Hall error signal');
grid on;

% For fun, also plot the intra-cavity power
subplot(2,1,2);
nIXprobe = getProbeNum(opt, 'IX_DC');
plot(poses(nEXdrive,:), sigDC(nIXprobe, :));
title('Intra-cavity power');
legend('Power circulating inside the cavity');
xlabel('cavity detuning [meters]');
ylabel('power [Watts]');
