% opt = addReadoutTelescope(opt, name, f, df, ts, ds, da, db)
%   add a generic readout telescope and 2 sinks
% 
% The arrangement constructed is a telescope, splitter mirror,
% and two sinks.  The idea is that the distances can be set to
% provide different Gouy phases for the probes set at each sink.
% (see also addReadout)
%
% name - base name for optics in the readout
% f, df - telescope parameters (see addTelescope)
% ts - splitter transmission (goes to sink B)
% ds - distance from telescope to splitter
% da - distance from splitter to sink A
% db - distance from splitter to sink B

function opt = addReadoutTelescope(opt, name, f, df, ts, ds, da, db)

  % names
  tele = [name '_TELE'];
  smir = [name '_SMIR'];
  snkA = [name 'a'];
  snkB = [name 'b'];

  % add optics
  opt = addTelescope(opt, tele, f, df);
  opt = addMirror(opt, smir, 45, 0, ts);
  opt = addSink(opt, snkA);
  opt = addSink(opt, snkB);

  % add links
  opt = addLink(opt, tele, 'out', smir, 'fr', ds);
  opt = addLink(opt, smir, 'fr', snkA, 'in', da);
  opt = addLink(opt, smir, 'bk', snkB, 'in', db);
end