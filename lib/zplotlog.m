% Log plot of magnitude and phase of a complex vector.
%
% zplotlog(f, h)

function zplotlog(f, h, varargin)

  % phase
  subplot(2, 1, 2)
  semilogx(f, 180 * angle(h) / pi, varargin{:})
  ylabel('phase [deg]')
  grid on

  % magnitude (done second so that it is "selected")
  subplot(2, 1, 1)
  loglog(f, abs(h), varargin{:})
  ylabel('mag')
  grid on

