% Add a probe of an optic's input/incident field.
%
% Arguments:
% opt - the optickle model
% name - probe name
% snOpt - the serial number or name of the source optic
% nameIn - the number or name of the input port
% freq - demodulation/RF frequency
% phase - demodulation/RF phase offset (degrees)
%
% The input/output ports of an optic depend on the type of optic.
% See also addPortOut, addLink, Mirror, Sink, etc.
%
% [opt, snProbe] = addProbeIn(opt, name, snOpt, nameIn, freq, phase);

function [opt, snProbe] = addProbeIn(opt, name, snOpt, nameIn, freq, phase)

  % check/parse field source
  snOpt = getSerialNum(opt, snOpt);
  portTo = getInputPortNum(opt.optic{snOpt}, nameIn);

  snLink = opt.optic{snOpt}.in(portTo);
  if snLink == 0
    error('Unavailable Field: %s not linked, so field is zero', ...
          getInputName(opt, snOpt, portFrom));
  end
  
  % create new probe
  [opt, snProbe] = addProbe(opt, name, snLink, freq, phase);
