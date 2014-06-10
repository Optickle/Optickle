classdef Mirror < Optic
  % Mirror is a type of Optic used in Optickle
  %
  % The Mirror object can be used for many purposes.  Generally
  % speaking a mirror has 2 inputs and 4 outputs, and can be
  % used for cavity optics, steering mirrors, 2-beam combiners or
  % splitters, etc.  (For mixing 4 beams, see the BeamSplitter class.)
  %
  % The inputs and outputs for a Mirror are:
  %
  % Inputs:
  % 1, fr, HR = front (HR side)
  % 2, bk, AR = back (AR side)
  %
  % Outputs:
  % 1, fr = front
  % 2, bk = back
  % 3, pi = pick-off sampling back input
  % 4, po = pick-off sampling back output
  %
  % Mirror objects are constructed with the following arguments
  % obj = Mirror(name, aio, Chr, Thr, Lhr, Rar, Lmd, Nmd)
  %
  % Optical Paramters:
  % aio - angle of incidence (in degrees)
  % Chr - curvature of HR surface (Chr = 1 / radius of curvature)
  % Thr - power transmission of HR suface
  % Lhr - power loss on reflection from HR surface
  % Rar - power reflection of AR surface
  % Nmd - refractive index of medium (1.45 for fused silica, SiO2)
  % Lmd - power loss in medium (one pass)
  %
  % default optical parameter values are:
  % [aio, Chr, Thr, Lhr, Rar, Lmd,  Nmd]
  % [  0,   0,   0,   0,   0,   0, 1.45]
  %
  % Chr is the mirror "curvature" which is the inverse of the radius
  % of curvature (c = 1/roc = 1/(2 * f), where f is the focal length).
  % Positive curvatures are used for concave, zero for a flat mirror,
  % and negative values for convex mirrors.
  %
  % Note that the three loss mechanisms (Lhr, Rar and Lmd) have default
  % values of zero.  Non-zero values will result in the entrance of
  % vacuum fluctuations, with a corresponding increase in quantum noise,
  % and an increase in time required to compute quantum noise.
  %
  % Example: a curved input mirror with 3km radius and 1% transmission
  % obj = Mirror('ITMX', 0, 1/3e3, 0.01);
  
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
    function obj = Mirror(name, varargin)
      % obj = Mirror(name, aio, Chr, Thr, Lhr, Rar, Lmd, Nmd)
      %
      % Optical Paramters:
      % aio - angle of incidence (in degrees)
      % Chr - curvature of HR surface (Chr = 1 / radius of curvature)
      % Thr - power transmission of HR suface
      % Lhr - power loss on reflection from HR surface
      % Rar - power reflection of AR surface
      % Lmd - power loss in medium (one pass)
      % Nmd - refractive index of medium (1.45 for fused silica, SiO2)
      %
      % default optical parameter values are:
      % [aio, Chr, Thr, Lhr, Rar, Lmd,  Nmd]
      % [  0,   0,   0,   0,   0,   0, 1.45]
      
      % deal with no arguments
      if nargin == 0
        name = '';
      end
      
      % build optic
      inNames = {{'fr' 'HR'}, {'bk' 'AR'}};
      outNames = {{'fr' 'HR'}, {'bk' 'AR'}, {'pi'}, {'po'}};
      driveNames = {'pos'};
      obj@Optic(name, inNames, outNames, driveNames);
      
      % deal with arguments
      errstr = 'Don''t know what to do with ';	% for argument error messages
      switch( nargin )
        case 0					% default constructor, do nothing
        case {1 2 3 4 5 6 7 8}
          % copy constructor
          %if isa(name, class(obj))
          %  obj = name;
          %  return
          %end
          
          % aoi, Chr, Thr, Lhr, Rar, Lmd, Nmd
          args = {0, 0, 0, 0, 0, 0, 1.45};
          args(1:(nargin - 1)) = varargin(1:end);
          
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

