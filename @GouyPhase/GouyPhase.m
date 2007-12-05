% GouyPhase is a type of Optic used in Optickle
%
% GouyPhase are used for changing the Gouy phase for readout.
% They are an abstraction of a Telescope which can be useful
% for interferometer design studies.
%
% obj = GouyPhase(name, phi)
%   phi - Gouy phase in radians, see also setPhase and getPhase
%
% A telescope has 1 input and 1 output.
% Input:  1, in
% Output: 1, out
%
% ==== Members
% Optic - base class members
% phase - Gouy phase in radians
%
% ==== Functions, those in Optic
%
%% Example: a quick telescope at transmission port
% obj = GouyPhase('TRAN_GOUY', pi / 2);

function obj = GouyPhase(varargin)

  obj = struct('phi', 0);
  obj = class(obj, 'GouyPhase', Optic);

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
      args = {'', 0};
      args(1:nargin) = varargin(1:end);
      [name, obj.phi] = deal(args{:});
      
      % build optic (a sink has no drives)
      obj.Optic = Optic(name, {'in'}, {'out'}, {});
    otherwise
      % wrong number of input args
      error([errstr '%d input arguments.'], nargin);
  end
