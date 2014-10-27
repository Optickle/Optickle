% [name, sn, port] = getSourceName(opt, snLink)
%
% Gets the display name of the source for the specified link.
%   Also available are the source optic's serial number,
%   and the output port to which this like is connected.
%
% Example:
% opt = optFP;
% getSourceName(opt, getFieldOut(opt, 'EX', 'fr'))

function [name, sn, port] = getSourceName(opt, snLink)

  sn = opt.link(snLink).snSource;
  port = opt.link(snLink).portSource;
  if sn==0
      name = '<REMOVED>';
      return
  end
  name = getOutputName(opt.optic{sn}, port);
