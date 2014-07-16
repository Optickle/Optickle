% Create an Optickle test case with
%   some modulators (AM or shift for TEM01/10, and PM/tilt)
%   a Gouy phase telescope and some detectors
%
% This can be useful for conducting simple tests of modulators
% and readout telescopes.

function opt = optTest

  % create model
  opt = Optickle(0);
  
  % add a source
  opt = addSource(opt, 'Laser', 1, 0, 3e3);

  % add an AM modulator
  %   opt = addModulator(opt, name, cMod)
  opt = addModulator(opt, 'AM', 1);
  opt = addLink(opt, 'Laser', 'out', 'AM', 'in', 0);

  % add an PM modulator
  opt = addModulator(opt, 'PM', 1i);
  opt = addLink(opt, 'AM', 'out', 'PM', 'in', 0);

  % add TRANS optics
  opt = addTelescope(opt, 'TRANS_T1', 2, [2.2 0.18]);
  opt = addMirror(opt, 'TRANS_S1', 45, 0, 0.5);
  opt = addSink(opt, 'TRANS');
  opt = addSink(opt, 'TRANS_90');

  opt = addLink(opt, 'PM', 'out', 'TRANS_T1', 'in', 0.3);
  opt = addLink(opt, 'TRANS_T1', 'out', 'TRANS_S1', 'bk', 0.1);
  opt = addLink(opt, 'TRANS_S1', 'bk', 'TRANS', 'in', 0.1);
  opt = addLink(opt, 'TRANS_S1', 'fr', 'TRANS_90', 'in', 1.7);
  
  % add TRANS probes
  opt = addProbeIn(opt, 'TRANS_DC', 'TRANS', 'in', 0, 0);	% DC
  opt = addProbeIn(opt, 'TRANS_90_DC', 'TRANS_90', 'in', 0, 0);	% DC

end
