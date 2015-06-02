% [opt] = removeProbe(opt, name);
%   remove a probe of some field. Warning this modifies the input opt.
%
% Arguments:
% opt - the optickle model
% name - name or serial number of probe
% nField - field index
% freq - demodulation frequency (Hz)
% phase - demodulation phase offset (degrees)
%

function [opt] = removeProbe(opt, name)

  % find the probe
  sn = getProbeNum(opt,name);
  
  warning('Removing probes modifies input Optickle model')

  % remove probe from optical model
  opt.probe = opt.probe(1:end~=sn);
  opt.Nprobe = opt.Nprobe - 1;
