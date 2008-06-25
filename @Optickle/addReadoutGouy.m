% opt = addReadoutGouy(opt, name, phi, linkIn)
% Add a mirror and set the guoy phases of the two output beams (fr and bk)
% at 90 degrees. 
%
%
% name   - sink name (also used as base name for probes in the readout)
%          The output are the two sinks at different guoy phases
%  phi   - gouy phase of probe A, phi + pi/2 is the guoy phase of probe B
% linkIn - sink name in input

function [opt, ProbeA, ProbeB] = addReadoutGouy(opt, name, phi, linkIn)

% Splitter and set of gouy phases

nameSplit = sprintf('%s%s', name, 'Split');
opt = addMirror(opt, nameSplit, 45, 0, 0.5, 0, 0, 0);
opt = addLink(opt, linkIn, 'out', nameSplit, 'fr', 2);

namePhaseA = sprintf('%s%s%s', 'Phase', name, 'A');
namePhaseB = sprintf('%s%s%s', 'Phase', name, 'B');

opt = addGouyPhase(opt, namePhaseA, phi);
opt = addGouyPhase(opt, namePhaseB, phi + pi/2);

opt = addLink(opt, nameSplit, 'fr', namePhaseA, 'in', 0.1);
opt = addLink(opt, nameSplit, 'bk', namePhaseB, 'in', 0.1);

[opt, ProbeA] = addSink(opt, name);
[opt, ProbeB] = addSink(opt, name);


opt = addLink(opt, namePhaseA, 'out', ProbeA, 'in', 2);
opt = addLink(opt, namePhaseB, 'out', ProbeB, 'in', 2);


