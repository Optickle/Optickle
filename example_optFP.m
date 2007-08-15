% An example of how to use Optickle and Simulink together:
%
% this example should be run in the Optickle directory
% pwd == .../Optickle/
addpath(genpath(pwd))

% create Fabry-Perot cavity model, and move a little off resonance
opt = optFP;
opt = setPosOffset(opt, 'IX', 1e-11);

% convert the simulink control system to a bunch of matrices
% to view the system use open_system('lscFP')
f = logspace(-1, 4, 100);
sCon = convertSimulink(opt, 'lscFP', f);

% tickle with controls (see tickle for more info)
[fDC, sigDC, sOpt, noiseOut] = tickle(opt, [], sCon);

% and make a plot, in this case showing a small radiation pressure effect
semilogx(f, abs(getTF(sOpt.mOpenLoop, 5, 1)))
grid on
