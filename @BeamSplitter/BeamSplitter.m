% BeamSplitter is a type of Optic used in Optickle
%
% A beam splitter is essentially 2 mirrors which share a common
% position.  The two sets of 4x2 transfer matrices, each identical
% to that of a mirror, produce an 8x4 matrix with no cross-terms.
% These two sets are simiply called A and B, as there is no
% distinguishing feature to differentiate them with.
%
% obj = BeamSplitter(name, aio, Chr, Thr, Lhr, Rar, Lmd, Nmd)
%
% Optical Paramters, Members, Functions, etc.
%   These are the same as for the Mirror class.
%
% default optical parameter values are:
% [aio, Chr, Thr, Lhr, Rar, Lmd,  Nmd]
% [ 45,   0, 0.5,   0,   0,   0, 1.45]
%
% A beam splitter has 4 inputs and 8 outputs.
% Inputs:
% 1, frA = front A
% 2, bkA = back A
% 3, frB = front B
% 4, bkB = back B
%
% Outputs:
% 1, frA = front
% 2, bkA = back
% 3, piA = pick-off sampling back input
% 4, poA = pick-off sampling back output
% 5, frB = front
% 6, bkB = back
% 7, piB = pick-off sampling back input
% 8, poB = pick-off sampling back output
%
%% Example: a beam splitter 49.5% transmission
% obj = BeamSplitter('BS', 45, 0, 0.495);

function obj = BeamSplitter(varargin)

  obj = struct('aoi', [], 'Chr', [], 'Thr', [], 'Lhr', [], ...
    'Rar', [], 'Lmd', [], 'Nmd', [], 'pos', 0, 'mechTF', []);

  obj = class(obj, 'BeamSplitter', Optic);

  errstr = 'Don''t know what to do with ';	% for argument error messages
  switch( nargin )
    case 0					% default constructor, do nothing
    case {1 2 3 4 5 6 7 8}
      % copy constructor
      arg = varargin{1};
      if( isa(arg, class(obj)) )
        obj = arg;
        return
      end

      % ==== name, aoi, Chr, Thr, Lhr, Rar, Lmd, Nmd
      args = {'', 45, 0, 0.5, 0, 0, 0, 1.45};
      args(1:nargin) = varargin(1:end);
      
      % build optic
      inNames = {{'frA'}, {'bkA'}, {'frB'}, {'bkB'}};
      outNames = {{'frA'}, {'bkA'}, {'piA'}, {'poA'}, ...
        {'frB'}, {'bkB'}, {'piB'}, {'poB'}};
      driveNames = {'pos'};
      obj.Optic = Optic(args{1}, inNames, outNames, driveNames);

      % store stuff in class
      [obj.aoi, obj.Chr, obj.Thr, obj.Lhr, ...
        obj.Rar, obj.Lmd, obj.Nmd] = deal(args{2:end});

    otherwise
      % wrong number of input args
      error([errstr '%d input arguments.'], nargin);
  end
