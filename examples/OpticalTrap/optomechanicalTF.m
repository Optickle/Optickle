function [tf, tfOscillator] = optomechanicalTF(f0, Q0, m , K, f)
% get the optomechanical transfer function of an oscillator
% (e.g. pendulum) in the presence of an optical spring.
%

%Mechanical spring constant and damping factor
Km = m * (2 * pi * f0)^2;    %old spring constant
bm = m * (2 * pi * f0) / Q0; %old damping factor


w = 2 * pi * f;
s = 1i * w;

tfOscillator = (1 / m) ./ (s.^2 + Km / m + s * bm / m);
tf           = (1 / m) ./ (s.^2 + (Km + K) / m + s * bm / m);