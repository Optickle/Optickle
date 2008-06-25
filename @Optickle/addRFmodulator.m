% [opt, sn] = addRFmodulator(opt, name, fMod, aMod)
%   Add an RF modulator to the model.
%
% name - name of this optic
% fMod - modulation frequency
% aMod - modulation index (imaginary for phase, real for amplitude)
%
% see RFModulator for more information

function [opt, sn] = addRFmodulator(opt, name, fMod, aMod)

  obj = RFmodulator(name, fMod, aMod);
  [opt, sn] = addOptic(opt, obj);
