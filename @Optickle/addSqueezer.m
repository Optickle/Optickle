
% [opt, sn] = addSqueezer(opt, name, loss, sqAng, sqdB)
%
% Parameters:
%
% loss - This represents the escape efficiency of the OPO 
%   (1-loss = escape efficiency)
% sqAng - squeezing angle
% sqdB - amount of squeezing in dB with perfect escape efficiency
%
% See squeezer for more options

function [ opt, sn ] = addSqueezer( opt, name, varargin )

  obj = Squeezer(name, varargin{:});
  [opt, sn] = addOptic(opt, obj);

end

