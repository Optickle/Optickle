% [opt, snProbe] = addProbeOut(opt, name, snOpt, nameOut, freq, phase);
%
% Add a probe of an optic's output field.  The probe is currently
% located at the end of the link carrying the output field (e.g.,
% at the input to the next optic).  This is because optic output
% fields are link input fields, which are not evaluated.  The only
% difference is the propagation phase, but it is better to use
% addProbeIn for clarity.
%
% Arguments:
% opt - the optickle model
% name - probe name
% snOpt - the serial number or name of the source optic
% nameOut - the number or name of the input port
% freq - demodulation/RF frequency
% phase - demodulation/RF phase offset (degrees)
%
% The input/output ports of an optic depend on the type of optic.
% see also addProbeIn

function [opt, snProbe] = addProbeOut(opt, name, snOpt, nameOut, freq, phase)

  % check/parse field source
  snOpt = getSerialNum(opt, snOpt);
  portFrom = getOutputPortNum(opt.optic{snOpt}, nameOut);

  snLink = opt.optic{snOpt}.out(portFrom);
  if snLink == 0
    error('Unavailable Field: %s not linked, so field is unknown', ...
          getOutputName(opt, snOpt, portFrom));
  end
  
  % create new probe
  [opt, snProbe] = addProbe(opt, name, snLink, freq, phase);
end
