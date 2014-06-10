classdef BeamSplitter < Optic
  % BeamSplitter is a type of Optic used in Optickle
  %
  % A beam splitter is essentially 2 mirrors which share a common
  % position.  The two sets of 4x2 transfer matrices, each identical
  % to that of a mirror, produce an 8x4 matrix with no cross-terms.
  % These two sets are simiply called A and B, as there is no
  % distinguishing feature to differentiate them with.
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
  % Example: a beam splitter 49.5% transmission
  % obj = BeamSplitter('BS', 45, 0, 0.495);
      
  properties
      aoi = [];    % angle of incidence (in degrees)
      Chr = [];    % curvature of HR surface (Chr = 1 / radius of curvature)
      Thr = [];    % power transmission of HR suface
      Lhr = [];    % power loss on reflection from HR surface
      Rar = [];    % power reflection of AR surface
      Lmd = [];    % refractive index of medium (1.45 for fused silica, SiO2)
      Nmd = [];    % power loss in medium (one pass)
      dWaist = []; % distance from the front of the mirror to the beam waist
  end

  methods
      function obj = BeamSplitter(name, varargin)
      % obj = BeamSplitter(name, aio, Chr, Thr, Lhr, Rar, Lmd, Nmd)
      %
      % Optical Paramters, Members, Functions, etc.
      %   These are the same as for the Mirror class.
      %
      % default optical parameter values are:
      % [aio, Chr, Thr, Lhr, Rar, Lmd,  Nmd]
      % [ 45,   0, 0.5,   0,   0,   0, 1.45]
      %
      
      % deal with no arguments
          if nargin == 0
              name = '';
          end

          % build optic
          inNames = {{'frA'}, {'bkA'}, {'frB'}, {'bkB'}};
          outNames = {{'frA'}, {'bkA'}, {'piA'}, {'poA'}, ...
                      {'frB'}, {'bkB'}, {'piB'}, {'poB'}};
          driveNames = {'pos'};
          obj@Optic(name, inNames, outNames, driveNames);

          % deal with arguments
          errstr = 'Don''t know what to do with ';	% for argument error messages
          switch( nargin )
            case 0					% default constructor, do nothing
            case {1 2 3 4 5 6 7 8}
              % copy constructor
              %if( isa(arg, class(obj)) )
              %    obj = arg;
              %    return
              %end

              %aoi, Chr, Thr, Lhr, Rar, Lmd, Nmd
              args = {45, 0, 0.5, 0, 0, 0, 1.45};
              args(1:(nargin-1)) = varargin(1:end);
      

              % store stuff in class
              [obj.aoi, obj.Chr, obj.Thr, obj.Lhr, ...
               obj.Rar, obj.Lmd, obj.Nmd] = deal(args{:});

            otherwise
              % wrong number of input args
              error([errstr '%d input arguments.'], nargin);
          end
      end
  end
end

