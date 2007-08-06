% Add a source to the model.
%
% [opt, sn] = addSource(opt, name, cMod)
% name - name of this optic
% cMod - modulation coefficient (1 for amplitude, i for phase)
%        this must be either a scalar, which is applied to all RF
%        field components, or a vector giving coefficients for each
%        RF field component.
%
% see Modulator for more information

function [opt, sn] = addModulator(opt, name, varargin)

  obj = Modulator(name, varargin{:});
  [opt, sn] = addOptic(opt, obj);
