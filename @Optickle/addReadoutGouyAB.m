% opt = addReadoutGouy(opt, name, phi, linkIn)
% Add a mirror and set the guoy phases of the two output beams (fr and bk)
% at 90 degrees. 
%
%
% name   - sink name (also used as base name for probes in the readout)
%          The output are the two sinks at different guoy phases
% phiA   - gouy phase of probe A
% phiB   - gouy phase of probe B
% linkIn - name of input optic
% portIn - name of port on input optic (default is 'out')

function [opt, ProbeA, ProbeB] = addReadoutGouyAB(opt, name, phiA, phiB, ...
    linkIn, portIn)

  if nargin < 6
    portIn = 'out';
  end
  
% Splitter and set of gouy phases

nameSplit = sprintf('%s%s', name, 'Split');
opt = addMirror(opt, nameSplit, 45, 0, 0.5, 0, 0, 0);
opt = addLink(opt, linkIn, portIn, nameSplit, 'fr', 2);

namePhaseA = sprintf('%s%s%s', 'Phase', name, 'A');
namePhaseB = sprintf('%s%s%s', 'Phase', name, 'B');

opt = addGouyPhase(opt, namePhaseA, phiA);
opt = addGouyPhase(opt, namePhaseB, phiB);

opt = addLink(opt, nameSplit, 'fr', namePhaseA, 'in', 0.1);
opt = addLink(opt, nameSplit, 'bk', namePhaseB, 'in', 0.1);

nameSinkA = sprintf('%s_SinkA', name);
nameSinkB = sprintf('%s_SinkB', name);
[opt, ProbeA] = addSink(opt, nameSinkA);
[opt, ProbeB] = addSink(opt, nameSinkB);

opt = addLink(opt, namePhaseA, 'out', ProbeA, 'in', 2);
opt = addLink(opt, namePhaseB, 'out', ProbeB, 'in', 2);

end