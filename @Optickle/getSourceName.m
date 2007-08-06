% Gets the display name of the source for the specified link.
%   Also available are the source optic's serial number,
%   and the output port to which this like is connected.
%
% [name, sn, port] = getSourceName(opt, snLink)

function [name, sn, port] = getSourceName(opt, snLink)

  sn = opt.link(snLink).snSource;
  port = opt.link(snLink).portSource;
  name = getOutputName(opt.optic{sn}, port);
