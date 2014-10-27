% [opt, snLink] = removeLink(opt, snFrom, nameOut, snTo, nameIn)
%   Remove a link.
%
% Arguments:
% opt - the optickle model
% snFrom - the serial number or name of the source optic (field origin)
% nameOut - the number or name of the output port (e.g., 1, 'fr', etc.)
% snTo - the serial number or name of the sink optic (field destination)
% nameIn - the number or name of the input port (e.g., 2, 'bk', etc.)
%
% The serial numbers of the optics (for snFrom and snTo) are
% returned by addOptic.  The name of the optic can also be used.
%
% The input/output ports of an optic depend on the type of optic.

function [opt, sn, length] = removeLink(opt, snFrom, nameOut, snTo, nameIn)

  % check/parse field source
  snFrom = getSerialNum(opt, snFrom);
  portFrom = getOutputPortNum(opt.optic{snFrom}, nameOut);
  
  % check/parse field sink
  snTo = getSerialNum(opt, snTo);
  portTo = getInputPortNum(opt.optic{snTo}, nameIn);

  sn = opt.optic{snFrom}.out(portFrom);
  sn2 = opt.optic{snTo}.in(portTo);
  if sn ~= sn2
    error('Not a valid Link');
  end
  
  length = opt.link(sn).len;

  % remove link from optical model
  nLink = numel(opt.link);
  
  if nLink ~= opt.Nlink
      error('Nic has broken something')
  end
  
  % this version breaks sigAC
  %opt.link = opt.link(1:nLink~=sn);
  %opt.Nlink = nLink-1;
  
  % just remove optic references from link
  opt.link(sn).snSource = 0;
  opt.link(sn).snSink = 0;
  opt.link(sn).portSource = 0;
  opt.link(sn).portSink = 0;
  
  % unlink the optics
  opt.optic{snFrom}.out(portFrom) = 0;
  opt.optic{snTo}.in(portTo) = 0;
end
