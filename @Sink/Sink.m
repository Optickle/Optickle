% Sink is a type of Optic used in Optickle
%
% Sinks are used for dumping fields, and for defining detector
% locations.  They are end points for field propagation and 
% sources of quantum noise.
%
% obj = Sink(name, loss)
%
% A sink has 1 input and 1 output.
% Input:  1, in, fr
% Output: 1, out, fr
%
% ==== Members
% Optic - base class members
% loss - fraction of incident power lost going from input to output
%   Usually this can be left at its default value of 1.  Smaller values
%   can be used to make attenuators.
%
% ==== Functions, those in Optic
%
%% Example: a sink at the REFL port
% obj = Sink('REFL');

function obj = Sink(varargin)

  obj = struct('loss', 1);
  obj = class(obj, 'Sink', Optic);

  errstr = 'Don''t know what to do with ';	% for argument error messages
  switch( nargin )
    case 0					% default constructor, do nothing
    case {1 2}
      % ==== copy constructor
      arg = varargin{1};
      if( isa(arg, class(obj)) )
        obj = arg;
        return
      end

      % ==== name, loss
      args = {'', 1};
      args(1:nargin) = varargin(1:end);
      [name, obj.loss] = deal(args{:});
      
      % build optic (a sink has no drives)
      obj.Optic = Optic(name, {'in'}, {'out'}, {});
    otherwise
      % wrong number of input args
      error([errstr '%d input arguments.'], nargin);
  end
