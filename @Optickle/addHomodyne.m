% opt.addHomodyne(name, nu, pol, phase, power, conObj, conOut)
% 
% This function adds a homodyne readout which consists of two sinks, two
% probes a splitter mirror, a source (for the local oscillator) and 
% all appropriate links. 
%
% The user must specify a particular frequency and polarization
% for the readout (ie the local oscillator polarization and frequency).
% The user also must specify the phase and power level of the LO.  The LO
% phase determines the measurement quadrature for the homodyne.  The second
% input for the splitter mirror will be connected to the output of the
% component specified in conObj and conOut.
%
% WARNING!!!!! in order to measure the quantum noise from the interferometer 
% correctly, the LO power must be significantly larger than the power 
% incident on the Homodyne from the interferometer (ideally by several
% orders of magnitude). 
%
% Arguements:
%
% name - base name for all objects in the homodyne
% nu - frequency for LO source
% pol - polarization for LO source
% phase - LO phase (in degrees)
% power - LO power
% conObj - Name of component which is connected to homodyne input
% conOut - Name of conObj output which is connected to homodyne input
%
% Example:
% opt.addHomodyne('HD', opt.nu(1), 1, 0, 100, 'Sqz1', 'out');
%
% This will create an object with 2 sinks 'HDA' and 'HDB', 2 probes
% 'HDA_DC' and 'HDB_DC', a source 'HD_LO', a splitter mirror 'HD_SMIR', and
% connect 'out' from 'Sqz1' to the input of the homodyne.  The LO is 100 W
% with S polarization and phase = 0.


function opt = addHomodyne(opt, name, nu, pol, phase, power, conObj, conOut)
  
  % names
  source = [name '_LO'];
  smir = [name '_SMIR'];
  snkA = [name 'A'];
  snkB = [name 'B'];
  
  % Pick out correct polarization and frequency component for LO
  vAmpRF = sqrt(power) * Optickle.matchFreqPol(opt, nu, pol);
  
  % add LO source
  opt.addSource(source, exp(1i * pi * phase / 180) * vAmpRF, 0, 0);

  % add Homodyne Splitter Mirror
  opt.addMirror(smir, 45, 0, 0.50, 0, 0, 0, 1.45);
  opt.addLink(source, 'out', smir, 'fr', 0.1);
  
  % add link from component at input to splitter mirror
  opt.addLink(conObj, conOut, smir, 'bk', 0.1);
  
  % add 2 Sinks and links to BS
  opt.addSink(snkA);
  opt.addSink(snkB);
  opt.addLink(smir, 'fr', snkA, 'in', 0);
  opt.addLink(smir, 'bk', snkB, 'in', 0);
  
  % add probes for Homodyne PDs
  opt.addProbeIn([snkA '_DC'], snkA, 'in', 0, 0);
  opt.addProbeIn([snkB '_DC'], snkB, 'in', 0, 0);

end