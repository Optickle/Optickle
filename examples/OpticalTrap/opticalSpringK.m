function K = opticalSpringK(Pin, delta, T1, L, f, lambda)
%
% K = opticalSpringK(Pin, delta, T1, L, f, lambda)
%
% Optical sping constant - from Corbitt's thesis
%
% Assumes T2=0 and high finesse
%
% Pin - cavity input power
% delta - cavity detuning in linewidths  (+ve for blue detuned
% springy side).
% L - cavity length [m]
% f - frequency [Hz]
% lambda - laser wavelength [m]

if nargin < 6
    lambda = 1064e-9;
end

delta = -delta; %Differs from Corbitt thesis - want +ve
                %spring constant for positive detuning

c     = 299792458;           %Speed of light
gamma = T1 * c / (4 * L);    %Cavity HWHM rad s^ - 1
w0    = 2 * pi * c / lambda; %Angular frequency of light c = f lambda


K0         = - (64 * Pin * w0) * delta / (T1^2 * c^2 * (1 + delta^2));
K          = K0 ./ (delta^2 + (1 + 2i * pi * f / gamma).^2);


