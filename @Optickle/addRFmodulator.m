% Add an RF modulator to the model.
%
% [opt, sn] = addRFmodulator(opt, name, fMod, aMod)
% name - name of this optic
% fMod - modulation frequency
% aMod - modulation index (imaginary for phase, real for amplitude)
%
% see Modulator for more information

function [opt, sn] = addRFmodulator(opt, name, fMod, aMod)

  obj = RFmodulator(name, fMod, aMod);
  [opt, sn] = addOptic(opt, obj);
