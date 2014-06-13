% [opt, sn] = addWaveplate(opt, name, lfw, theta)
%   Add an waveplate to the model.
%
% name - name of this optic
% lfw - fraction of wave
% theta - rotation angle
%
% see Waveplate for more information

function [opt, sn] = addWaveplate(opt, name, lfw, theta)

  obj = Waveplate(name, lfw, theta);
  [opt, sn] = addOptic(opt, obj);
