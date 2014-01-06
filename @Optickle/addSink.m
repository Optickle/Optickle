% [opt, sn] = addSink(opt, name, loss)
%   Add a sink to the model.
%
% loss - power loss from input to output (default = 1)
%
% Sinks can be used as place holders for probes, or as
% beam attenuators when loss < 1.  See optFP for examples.

function [opt, sn] = addSink(opt, name, varargin)

  obj = Sink(name, varargin{:});
  [opt, sn] = addOptic(opt, obj);
