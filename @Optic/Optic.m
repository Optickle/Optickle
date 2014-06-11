classdef Optic < handle
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
  
  properties (SetAccess = {?Optic, ?Optickle})
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
    
    function [mOptAC, mOpt] = getFieldMatrixAC(obj, pos, par)
      % return default expansion of the drive matrix
      mOpt = getFieldMatrix(obj, pos, par);
      mOptAC = Optic.expandFieldMatrixAF(mOpt);
    end
    
    function [mGenAC, mGen] = getGenMatrix(obj, pos, par, varargin)
      % return default expansion of the field matrix
      mCplMany = getDriveMatrix(obj, pos, par, varargin{:});
      
      %%% Expand 3D coupling matrix to mGen
      
      % number of outputs and drives
      NoutRF = obj.Nout * par.Nrf;
      Ndrv = obj.Ndrv;
      
      % fill in the generation matrix
      mGen = zeros(NoutRF, Ndrv);
      vDC = par.vDC;
      for n = 1:Ndrv
        mGen(:, n) = mCplMany(:, :, n) * vDC;
      end
      
      % expand to upper and lower audio SBs
      mGenAC = [mGen; conj(mGen)];
    end
    
  end % methods
  
  methods (Abstract)
    % input to output field matrix (Nout*Nrf x Nin*Nrf)
    mOpt = getFieldMatrix(obj, pos, par);
  end
  
  methods (Static)
    function mOptAC = expandFieldMatrix(mOpt, Nrf)
      % expand a Nout x Nin field matrix
      % to all RF components and audio SBs
      
      % make room for upper and lower audio SBs
      NinRF = Nrf * size(mOpt, 2);
      NoutRF = Nrf * size(mOpt, 1);
      mOptAC = sparse(2 * NoutRF, 2 * NinRF);
      
      % expand to all RF components
      mOptRF = Optic.blkdiagN(mOpt, Nrf);
      
      % fill in block diagonal matrix
      mOptAC(1:NoutRF, 1:NinRF) = mOptRF;
      mOptAC(NoutRF + (1:NoutRF), NinRF + (1:NinRF)) = conj(mOptRF);
    end
    
    function mOptAC = expandFieldMatrixRF(mOpt, Nrf)
      % expand a (2 * Nout) x (2 * Nin) field matrix
      % (i.e., one with upper and lower audio SBs)
      % to all RF components
      
      % make room for upper and lower audio SBs
      Nin = size(mOpt, 2) / 2;
      Nout = size(mOpt, 1) / 2;
      NinRF = Nrf * Nin;
      NoutRF = Nrf * Nout;
      NinAC = 2 * NinRF;
      NoutAC = 2 * NoutRF;
      mOptAC = sparse(NoutAC, NinAC);
      
      %%% fill in block diagonal matrices into each AF quadrant
      
      % upper left quadrant
      mOptAC(1:NoutRF, 1:NinRF) = ...
        Optic.blkdiagN(mOpt(1:Nout, 1:Nin), Nrf);
      
      % upper right quadrant (only for non-linear optics)
      mOptAC(NoutRF + (1:NoutRF), (1:NinRF)) = ...
        Optic.blkdiagN(mOpt(Nout + (1:Nout), 1:Nin), Nrf);
      
      % lower left quadrant (only for non-linear optics)
      mOptAC(1:NoutRF, NinRF + (1:NinRF)) = ...
        Optic.blkdiagN(mOpt(1:Nout, Nin + (1:Nin)), Nrf);
      
      % lower right quadrant
      mOptAC(NoutRF + (1:NoutRF), NinRF + (1:NinRF)) = ...
        Optic.blkdiagN(mOpt(Nout + (1:Nout), Nin + (1:Nin)), Nrf);
    end
    
    function mOptAC = expandFieldMatrixAF(mOpt)
      % expand a Nout x Nin field matrix,
      % or a (Nrf * Nout) x (Nrf * Nin) field matrix
      % (i.e., one with RF components, but not audio SBs)
      % to both audio SBs
      
      % make room for upper and lower audio SBs
      NinRF = size(mOpt, 2);
      NoutRF = size(mOpt, 1);
      mOptAC = sparse(2 * NoutRF, NinRF);
      
      % fill in block diagonal matrix
      mOptAC(1:NoutRF, 1:NinRF) = mOpt;
      mOptAC(NoutRF + (1:NoutRF), NinRF + (1:NinRF)) = conj(mOpt);
    end
    
    function mGenAC = buildGenMatrix(varargin)
      % builds the audio SB generation matrix from
      % multiple coupling matrices and the input DC fields
      %
      % last argument is vDC, others are coupling matrices
      % coupling matrices should be NoutRF x NinRF
      % returned mGen is (2 * NoutRF) x Ndrv
      %
      % Example:
      % mGenAC = buildGenMatrix(mCpl1, mCpl2, vDC)
      
      % convert arguments
      if nargin < 2
        error('Need at least one coupling matrix and vDC')
      else
        mCplList = varargin(1:(end - 1));
        vDC = varargin{end};
      end
      
      % number of outputs and drives
      NoutRF = size(mCplList{1}, 1);
      Ndrv = numel(mCplList);
      
      % fill in the generation matrix
      mGen = zeros(NoutRF, Ndrv);
      for n = 1:Ndrv
        mGen(:, n) = mCplList{n} * vDC;
      end
      
      % expand to upper and lower audio SBs
      mGenAC = [mGen; conj(mGen)];
    end
    
    function m = blkdiagN(m0, N)
      % construct a block diagonal matrix with N copies of
      %   the input matrix.  See also blkdiag.
      %
      % m = blkdiagN(m, N);
      
      % prepare an N element cell array
      tmp = cell(N, 1);
      
      % fill all N elements with the input matrix
      [tmp{:}] = deal(m0);
      
      % make a block diagonal matrix with these matrices
      m = blkdiag(tmp{:});
    end
    
  end  % methods (Static)
  
end % Optic

