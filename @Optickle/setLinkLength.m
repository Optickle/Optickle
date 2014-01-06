% opt = setLinkLength(opt, sn, len)
%   set the length of a link
% 
% opt = setLinkLength(opt, sn, len)
% sn - serial number of a link
%   The serial number of a link matches that of its output
%   field (or FEP).  An output field index can be found either
%   by the optic is goes into (with getFieldIn) or the optic
%   where the link originates (with getFieldOut).
% len - new length of this link
%
% see also getLinkLengths
%
% Example:
% opt = optFP;
% sn = getFieldIn(opt, 'IX', 'bk');
% vl = getLinkLengths(opt);
% disp(vl(sn))
% opt = setLinkLength(opt, sn, 4);
% vl = getLinkLengths(opt);
% disp(vl(sn))

function opt = setLinkLength(opt, sn, len)

  opt.link(sn).len = len;
