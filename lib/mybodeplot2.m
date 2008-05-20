function [varargout] = mybodeplot2(varargin)

% Makes a nice Bode Plot from a frequency vector 'f'
% and a vector 'z' of complex numbers
% z can also be a bunch of columns 
% e.g. mybodeplot2(f,[hDARM hCARM hPRC hMICH]) 
%
% Syntax: mybodeplot2(f,z)  or [top,bottom] = mybodeplot2(f,z)
%



deg = 180/pi;

% Check input arguements for correctness
if nargin == 2
  x = varargin{1};
  y = varargin{2};
elseif nargin > 3
  error('%s','ERROR: Too many arguments')
end




bottom = subplot('position',[0.13 0.1 0.82 0.4]);
semilogx(x, angle(y)*deg);
set(bottom,'YTick',[-180:45:180]);
axis tight
grid
set(bottom,'GridLineStyle','--');
xlabel('Frequency (Hz)');
ylabel('Phase (deg)');

top = subplot('position',[0.13 0.52 0.82 0.4]);
semilogx(x,20*log10(abs(y)));
set(top,'XTickLabel',[]);
set(top,'GridLineStyle','--');
axis tight;
grid
ylabel('Mag (dB)');


% Parse the output arguments to give plot handels
if nargout == 0
  
elseif nargout == 2
  varargout{1} = top;
  varargout{2} = bottom;
else
  error('Needs 0 or 2 output args')
end

return
