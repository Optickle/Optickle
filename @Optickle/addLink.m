% [opt, snLink] = addLink(opt, snFrom, nameOut, snTo, nameIn, len)
%   Add a link between two optickle nodes.
%
% Arguments:
% opt - the optickle model
% snFrom - the serial number or name of the source optic (field origin)
% nameOut - the number or name of the output port (e.g., 1, 'fr', etc.)
% snTo - the serial number or name of the sink optic (field destination)
% nameIn - the number or name of the input port (e.g., 2, 'bk', etc.)
% len - the length of the link
%
% The serial numbers of the optics (for snFrom and snTo) are
% returned by addOptic.  The name of the optic can also be used.
%
% The input/output ports of an optic depend on the type of optic.

function [opt, snLink] = addLink(opt, snFrom, nameOut, snTo, nameIn, len)

  % check/parse field source
  snFrom = getSerialNum(opt, snFrom);
  portFrom = getOutputPortNum(opt.optic{snFrom}, nameOut);

  sn = opt.optic{snFrom}.out(portFrom);
  if sn ~= 0
    error('Unavailable Source: %s already linked to %s', ...
          getSourceName(opt, sn), getSinkName(opt, sn));
  end

  % check/parse field sink
  snTo = getSerialNum(opt, snTo);
  portTo = getInputPortNum(opt.optic{snTo}, nameIn);
  
  sn = opt.optic{snTo}.in(portTo);
  if sn ~= 0
    error('Unavailable Sink: %s already linked to %s', ...
          getSourceName(opt, sn), getSinkName(opt, sn));
  end

  % create new link
  snLink = opt.Nlink + 1;    % link serial number
  newLink = struct('sn', snLink, 'len', len, 'phase', [], ...
                   'snSource', snFrom, 'portSource', portFrom, ...
                   'snSink', snTo, 'portSink', portTo);

  % add new link to optical model
  opt.link(snLink, 1) = newLink;
  opt.Nlink = snLink;

  % link the optics
  opt.optic{snFrom}.out(portFrom) = snLink;
  opt.optic{snTo}.in(portTo) = snLink;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% modal stuff for next version
function modalStuff

  % update sink output basis
  qx = opt.optic(snFrom).qx(portFrom);
  qy = opt.optic(snFrom).qy(portFrom);
  if qx == 0 || qy == 0
    error('%s basis not yet defined.  Try linking an input to %s.', ...
          getOutputName(opt, snFrom, portFrom), opt.optic(snFrom).name);
  end

  qm = opt.optic(snTo).qm(:, portTo);
  for n = 1:opt.optic(snTo).Nout
    % x-axis
    if ~isempty(qm(n).x)
      oldQX = opt.optic(snTo).qx(n);
      newQX = applyOpHG(qm(n).x, qx + len);
      if oldQX == 0
        opt.optic(snTo).qx(n) = newQX;
      elseif abs(newQX - oldQX) / abs(oldQX) > 0.01
        warning('Basis badly matched qa = (%f, %f), qb = (%f, %f)', ...
                real(oldQX), -imag(oldQX), real(newQX), -imag(newQX))
      end
    end
  
    % y-axis
    if opt.optic(snTo).qy(n) == 0 && ~isempty(qm(n).y)
      opt.optic(snTo).qy(n) = applyOpHG(qm(n).y, qy + len);
    end
  end
  
end
