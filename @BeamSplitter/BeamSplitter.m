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
      
  properties (SetAccess = protected)
    aoi = [];    % angle of incidence (in degrees)
    Chr = [];    % curvature of HR surface (Chr = 1 / radius of curvature)
    Thr = [];    % power transmission of HR suface
    Lhr = [];    % power loss on reflection from HR surface
    Rar = [];    % power reflection of AR surface
    Lmd = [];    % refractive index of medium (1.45 for fused silica, SiO2)
    Nmd = [];    % power loss in medium (one pass)
    dWaist = []; % distance from the front of the mirror to the beam waist
  
    % a mirror contained here to do calculations
    % most methods of BS rely on Mirror methods, combining the results
    % for side A and side B.
    mir = [];
  end
  
  properties (Constant)
    % map from side-A and B inputs to mirror inputs
    mInA = [eye(2), zeros(2)];
    mInB = [zeros(2), eye(2)];
    
    % map from mirror outputs to side-A and B outputs
    mOutA = [eye(4); zeros(4)];
    mOutB = [zeros(4); eye(4)];
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
      
      % set internal mirrors to match
      obj.mir = Mirror('mir', obj.aoi, obj.Chr, obj.Thr, obj.Lhr, ...
            obj.Rar, obj.Lmd, obj.Nmd);
    end      
    function [vThr, vLhr, vRar, vLmd] = getVecProperties(obj, lambda, pol)
      % optic parametes as vectors for each field component
      %
      % [vThr, vLhr, vRar, vLmd] = getVecProperties(obj, lambda, pol)
      
      [vThr, vLhr, vRar, vLmd] = obj.mir.getVecProperties(lambda, pol);
    end
    %%%% Protected Properties %%%%
    function obj = setPosOffset(obj, pos)
      % set the position offset for an optic
      %
      % obj = setPosOffset(obj, pos)
      
      if length(pos) ~= obj.Ndrive
        error('%s: drive positions not equal to number of drives (%d ~= %d)', ...
          obj.name, length(pos), obj.Ndrive);
      end
      %obj.pos = pos(:); %fix this for BS mir object
      obj.mir = setPosOffset(obj.mir,pos);
    end
    function obj = setMechTF(obj, mechTF, nDOF)
        % sets the mechTF property for the BS and internal mirror object
        
        if nargin < 3
            nDOF = Optickle.tfPos;
        end
        
        % set mechTF of sub-mirror
        obj.mir = setMechTF(obj.mir,mechTF,nDOF);
        % finally call the superclass method
        obj = setMechTF@Optic(obj,mechTF,nDOF);
    end
    
    %%%% Hermite Gauss Basis %%%%

    function qm = getBasisMatrix(obj)
      % Compute basis transform matrix
      %
      % qm = getBasisMatrix(obj)
      
      qm = obj.mir.getBasisMatrix();
      mop = repmat(OpHG(NaN), 4, 2);
      
      qm = [qm,mop;mop,qm]; % block diagonal
    end
  end
  
  methods (Static)
    function [mInArf, mInBrf, mOutArf, mOutBrf] = getMirrorIO(Nrf)
      % map from side-A and B inputs to mirror inputs
      mInArf = blkdiagN(BeamSplitter.mInA, Nrf);
      mInBrf = blkdiagN(BeamSplitter.mInB, Nrf);
      
      % map from mirror outputs to side-A and B outputs
      mOutArf = blkdiagN(BeamSplitter.mOutA, Nrf);
      mOutBrf = blkdiagN(BeamSplitter.mOutB, Nrf);
    end
  end
end

