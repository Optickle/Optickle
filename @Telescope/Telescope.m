% Telescope is a type of Optic used in Optickle
%
% Telescopes are used for changing the beam size to match
% cavities, or to add Gouy phase for readout.  A telescope
% is made up of N + 1 lenses with N distances between them.
%
% NOTE: the audio phase accumulated while propagating through
% a telescope is NOT included.  Typically this phase is very
% small (e.g., for a 1 meter telescope, a 300Hz audio SB should
% gain 1e-6 radians of phase).  In special cases where the
% audio phase is of interest, break the telescope into individual
% lenses (with the distaces being represented by links).
%
% obj = Telescope(name, f)
%   or, to add more lenses after the first append an
%   Nx2 matrix of distance and focal length pairs
% obj = Telescope(name, f, df)
%
% A telescope has 1 input and 1 output.
% Input:  1, in, fr
% Output: 1, out, fr
%
% ==== Members
% Optic - base class members
% f - focal length of first lens
% df - distances from previous lens and lens focal length
%      for lenses after the first
%
% ==== Functions, those in Optic
%
%% Example: a telescope at transmission port (10x reduction, then focus)
% obj = Telescope('TRAN_TELE', 2, [2.2 0.2; 0.2 0.3]);

function obj = Telescope(varargin)

  obj = struct('f', 1, 'df', []);
  obj = class(obj, 'Telescope', Optic);

  errstr = 'Don''t know what to do with ';	% for argument error messages
  switch( nargin )
    case 0					% default constructor, do nothing
    case {1 2 3}
      % ==== copy constructor
      arg = varargin{1};
      if( isa(arg, class(obj)) )
        obj = arg;
        return
      end

      % ==== name, loss
      args = {'', 1, []};
      args(1:nargin) = varargin(1:end);
      [name, obj.f, obj.df] = deal(args{:});
      
      % build optic (a sink has no drives)
      obj.Optic = Optic(name, {'in'}, {'out'}, {});
    otherwise
      % wrong number of input args
      error([errstr '%d input arguments.'], nargin);
  end
