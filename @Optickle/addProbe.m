% Add a probe of some field.
%
% Arguments:
% opt - the optickle model
% name - probe name
% nField - field index
% freq - demodulation frequency (Hz)
% phase - demodulation phase offset (degrees)
%
% The field index (nField) is not checked for validity.  Use addProbeIn
% or addProbeOut instead.
%
% [opt, snProbe] = addProbe(opt, name, nField, freq, phase);

function [opt, snProbe] = addProbe(opt, name, nField, freq, phase)

  % create new probe
  snProbe = opt.Nprobe + 1;		% probe serial number
  newProbe = struct('sn', snProbe, 'name', name, 'nField', nField, ...
                    'freq', freq, 'phase', phase);

  % add new probe to optical model
  opt.probe(snProbe, 1) = newProbe;
  opt.Nprobe = snProbe;
