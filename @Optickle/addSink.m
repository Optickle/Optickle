% Add a sink to the model.
%
% [opt, sn] = addSink(opt, name, loss)
% loss - power loss from input to output (default = 1)

function [opt, sn] = addSink(opt, name, varargin)

  obj = Sink(name, varargin{:});
  [opt, sn] = addOptic(opt, obj);
