% Add a probe of an optic's input/incident field.
% This is a duplicate of addProbeIn, please use that instead!
%
% [opt, snProbe] = addProbeAt(opt, name, snOpt, nameIn, freq, phase);

function [opt, snProbe] = addProbeAt(opt, name, snOpt, nameIn, freq, phase)

  [opt, snProbe] = addProbeIn(opt, name, snOpt, nameIn, freq, phase);
