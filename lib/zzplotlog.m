% Log plot of magnitude and phase of a complex vector.
%
% zplotlog(f, h)

function zzplotlog(f, h, varargin)

  % phase
  subplot(212)
  semilogx(f, 180 * angle(h) / pi, varargin{:})
  ylabel('Phase [deg]')
  grid on

  % magnitude (done second so that it is "selected")
  subplot(211)
  loglog(f, abs(h), varargin{:})
  ylabel('Mag')
  grid on

