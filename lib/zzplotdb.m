% Log plot of magnitude (in db) and phase (in degrees) of a complex vector.
%
% zplotdb(f, h)

function zzplotdb(f, h, varargin)

  % phase
  subplot(212)
  semilogx(f, 180 * angle(h) / pi, varargin{:})
  ylabel('Phase [deg]')
  grid on

  % magnitude (done second so that it is "selected")
  subplot(211)
  semilogx(f, 20 * log10(abs(h)), varargin{:})
  ylabel('Mag [dB]')
  grid on

