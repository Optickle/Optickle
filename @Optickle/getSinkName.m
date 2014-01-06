% [name, sn, port] = getSinkName(opt, snLink)
%
% Gets the display name of the sink for the specified link.
%   Also available are the sink optic's serial number,
%   and the input port to which this like is connected.
%
% see also getSourceName

function [name, sn, port] = getSinkName(opt, snLink)

  sn = opt.link(snLink).snSink;
  port = opt.link(snLink).portSink;
  name = getInputName(opt.optic{sn}, port);
