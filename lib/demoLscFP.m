% An example of how to use Optickle and Simulink together:

function demoLscFP

  % create Fabry-Perot cavity model
  opt = optFP;

  % convert the simulink control system to a bunch of matrices
  % to view the system use open_system('lscFP')
  f = logspace(-1, 4, 100);
  sCon = convertSimulink(opt, 'lscFP', f);

  % tickle with controls (see tickle for more info)
  %   at small offset from resonance for EX position
  nEX = getDriveIndex(opt, 'EX');
  pos = zeros(opt.Ndrive, 1);
  pos(nEX) = 1e-12;

  [fDC, sigDC, sOpt, noiseOut] = tickle(opt, pos, sCon);

  % and make a plot showing the locking loop gain
  subplot(2, 1, 1)
  loglog(f, abs(getTF(sOpt.mOpenLoop, 1, 1)))
  title('Locking Loop Open-Loop Gain', 'fontsize', 18);
  xlabel('Hz')
  ylabel('gain')
  grid on

  % and plot showing the oscillator phase-noise to REFL_I TF
  subplot(2, 1, 2)
  loglog(f, abs(getTF(sOpt.mInOut, 4, 3)))
  title('Oscillator phase-noise to REFL\_I', 'fontsize', 18);
  xlabel('Hz')
  ylabel('magnitude')
  grid on
