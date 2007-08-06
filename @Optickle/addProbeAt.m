% Add a probe of an optic's input/incident field.
% This is a duplicate of addProbeIn, please use that instead!
%
% opt = addProbeAt(opt, name, snOpt, nameIn, freq, phase);

function opt = addProbeAt(opt, name, snOpt, nameIn, freq, phase)

  opt = addProbeIn(opt, name, snOpt, nameIn, freq, phase);
