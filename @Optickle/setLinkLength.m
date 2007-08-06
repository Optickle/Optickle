% set the length of a link
% 
% opt = setLinkLength(opt, sn, len)
% sn - serial number of a link
% len - new length of this link

function opt = setLinkLength(opt, sn, len)

  opt.link(sn).len = len;
