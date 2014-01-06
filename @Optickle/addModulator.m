% [opt, sn] = addModulator(opt, name, cMod)
%   Add a modulator to the model.
%
% name - name of this optic
% cMod - modulation coefficient (1 for amplitude, i for phase)
%        this must be either a scalar, which is applied to all RF
%        field components, or a vector giving coefficients for each
%        RF field component.
%
% Modulators can be used to modulate a beam.  These are not for
% continuous modulation (i.e., for making RF sidebands), but rather
% for measuring transfer functions (e.g., for frequency or intensity
% noise couplings).
%
% see Modulator for more information

function [opt, sn] = addModulator(opt, name, varargin)

  obj = Modulator(name, varargin{:});
  [opt, sn] = addOptic(opt, obj);
