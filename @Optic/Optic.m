classdef Optic
% This is the base class for optics used in Optickle
%
% An Optic is a general optical component (mirror, lens, etc.).
% Each type of optic has a fixed number of inputs and outputs,
% and names for each.  The details which characterize a given
% optic are specified in the derived types.
%
% ==== Important User Methods
% getFieldIn - the index of an input field at some port
% getFieldOut - the index of an output field at some port
%
% getInputPortNum - the number of an input port, given its name
% getOutputPortNum - the number of an output port, given its name
%
% getInputName - display name for some input port
% getOutputName - display name for some output port
%

  
  properties (SetAccess = protected)
     sn = 0;            % optic serial number
     name = '';         % optic name string
     
     Nin = 0;           % number of input fields
     in = [];           % vector of input link serial numbers (Nin x 1)
     inNames = [];      % cell array of input names (Nin x 1)

     Nout = 0;          % number of output fields
     outNames = {};     % cell array of output names (Nout x 1)
     out = [];          % vector of output link serial numbers (Nout x 1)
     qxy = [];          % vector of output basis parameters (Nout x 2)

     Ndrive = 0;        % number of drive inputs
     driveNames = {};   % cell array of drive names (Ndrive x 1)
     drive = [];        % vector of drive indices (Ndrive x 1)
     pos = [];          % static drive offset (see setPosOffset)
     
     % mechTF - radiation force response rad/(N m)
     %   This is the optic's transfer-funtion from radiation pressure
     %   to drive position.  (see setMechTF, getMechTF, getMechResp)
     mechTF = [];

     % mechTFpit - radiation torque response rad/(N m)
     %   takes radiation torque around the X axis, and outputs
     %   rotations around the same axis (pitch) with units
     %   of rad/(N m).
     mechTFpit = [];
  end
  
  methods
    function obj = Optic(varargin)
      % constructor: default, or with 4 arguments
      % obj = Optic;
      % obj = Optic(name, inNames, outNames, driveNames);
      
      errstr = 'Don''t know what to do with ';	% for argument error messages
      switch( nargin )
        case 0					% default constructor, do nothing
%         case 1
%           % copy constructor
%           arg = varargin{1};
%           if( isa(arg, class(obj)) )
%             obj = arg;
%           else
%             error([errstr 'a %s.'], class(arg));
%           end
        case 4
          % sn, name, inNames, outNames, driveNames
          [obj.name, obj.inNames, obj.outNames, obj.driveNames] = ...
            deal(varargin{:});
          obj.Nin = length(obj.inNames);
          obj.Nout = length(obj.outNames);
          obj.Ndrive = length(obj.driveNames);
          obj.in = zeros(obj.Nin, 1);
          obj.out = zeros(obj.Nout, 1);
          obj.qxy = zeros(obj.Nout, 2);
          obj.drive = zeros(obj.Ndrive, 1);
          obj.pos = zeros(obj.Ndrive, 1);
          
          % check name cell array structure, input
          for n = 1:obj.Nin
            if ischar(obj.inNames{n})
              obj.inNames{n} = cellstr(obj.inNames{n});
            elseif ~iscell(obj.inNames{n})
              error('Input names must be strings, or cell arrays of strings.')
            end
          end
          
          % check name cell array structure, output
          for n = 1:obj.Nout
            if ischar(obj.outNames{n})
              obj.outNames{n} = cellstr(obj.outNames{n});
            elseif ~iscell(obj.outNames{n})
              error('Output names must be strings, or cell arrays of strings.')
            end
          end
          
          % check name cell array structure, drive
          for n = 1:obj.Ndrive
            if ischar(obj.driveNames{n})
              obj.driveNames{n} = cellstr(obj.driveNames{n});
            elseif ~iscell(obj.driveNames{n})
              error('Drive names must be strings, or cell arrays of strings.')
            end
          end
        otherwise
          % wrong number of input args
          error([errstr '%d input arguments.'], nargin);
      end
    end % constructor
    
    function mOptAC = getFieldMatrixAC(obj, pos, par)
      % make room for upper and lower audio SBs
      NinRF = par.Nrf * obj.Nin;
      NoutRF = par.Nrf * obj.Nout;
      mOptAC = sparse(2 * NoutRF, 2 * NinRF);
      
      % fill in block diagonal matrix
      mOpt = getFieldMatrix(obj, pos, par);
      mOptAC(1:NoutRF, 1:NinRF) = mOpt;
      mOptAC(NoutRF + (1:NoutRF), NinRF + (1:NinRF)) = conj(mOpt);
    end
    
  end % methods
  
  methods (Abstract)
    % input to output field matrix (Nout*Nrf x Nin*Nrf)
    mOpt = getFieldMatrix(obj, pos, par);
  end
  
end % Optic

