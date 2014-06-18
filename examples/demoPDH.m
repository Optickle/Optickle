%% demoPDH  Show Pound-Drever-Hall error signal vs cavity length sweep

% Construct a model of a Fabry-Perot cavity
opt = optFP();

% Retrieve some drive and probe serial numbers from the Optickle model
nEXdrive = getDriveNum(opt, 'EX', 'pos');
nREFL_Iprobe = getProbeNum(opt, 'REFL_I');
nREFL_Qprobe = getProbeNum(opt, 'REFL_Q');

% Set up the limit of our sweep
pos = zeros(opt.Ndrive, 1);
pos(nEXdrive) = -5e-9; % [meters]

% Do the sweep
[poses, sigDC, fDC] = sweepLinear(opt, pos, -pos, 201);

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