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
    
    %%%% Matrix Building %%%%

    function [mOptAC, mGen, mRad, mFrc, vRspAF, mQuant] ...
        = getMatrices(obj, pos, par)
      % Get field transfer, reaction, drive and quantum matrices for this optic.
      %   see also getFieldMatrix, getReactMatrix, getDriveMatrix and getNoiseMatrix
      %
      % The parameter struct is
      %  par.c = opt.c;
      %  par.lambda = opt.lambda;
      %  par.k = opt.k;
      %  par.Nrf = Nrf;
      %  par.vFrf = vFrf;
      %  par.Naf = Naf;
      %  par.vFaf = f;
      %  par.vDC = mIn{n} * vDC;   % DC fields at each optic's inputs
      %
      % [mOptAC, mGen, mRad, mFrc, mRsp, mQuant] = getMatrices(obj, pos, par)
      
      
      % optical field transfer matrix
      mOptAC = getFieldMatrixAC(obj, pos, par);
      
      % reaction, drive and noise matrices (only used in AC computation)
      mGen = getGenMatrix(obj, pos, par);
      [mRad, mFrc, vRspAF] = getReactMatrix(obj, pos, par);
      mQuant = getNoiseMatrix(obj, pos, par);
    end
    function [mOptAC, mGen, mRad, mFrc, vRspAF, mQuant] ...
        = getMatrices01(obj, pos, par)
      % Get field transfer, reaction and drive TEM 01 matrices for this optic.
      %   see also getMatrices, getFieldMatrix, getReactMatrix01 and
      %   getDriveMatrix01
      %
      % [mOptAC, mGen, mRad, mFrc, mRsp, mQuant] = getMatrices01(obj, pos, par)
      
      % optical field transfer matrix
      mOptAC = getFieldMatrix01(obj, pos, par);
      
      % reaction, drive and noise matrices (only used in AC computation)
      mGen = getGenMatrix01(obj, pos, par);
      [mRad, mFrc, vRspAF] = getReactMatrix01(obj, pos, par);
      mQuant = getNoiseMatrix01(obj, pos, par);
    end
    function [mOptAC, mGen, mRad, mFrc, vRspAF, mQuant] ...
        = getMatrices10(obj, pos, par)
      % Get field transfer, reaction and drive TEM 10 matrices for this optic.
      %   see also getMatrices, getFieldMatrix, getReactMatrix10 and
      %   getDriveMatrix10
      %
      % [mOptAC, mGen, mRad, mFrc, mRsp, mQuant] = getMatrices10(obj, pos, par)
      
      % optical field transfer matrix
      mOptAC = getFieldMatrix10(obj, pos, par);
      
      % reaction, drive and noise matrices (only used in AC computation)
      mGen = getGenMatrix10(obj, pos, par);
      [mRad, mFrc, vRspAF] = getReactMatrix10(obj, pos, par);
      mQuant = getNoiseMatrix10(obj, pos, par);
    end
    
    function [mOptAC, mOpt] = getFieldMatrixAC(obj, pos, par)
      % return default expansion of the drive matrix
      mOpt = getFieldMatrix(obj, pos, par);
      mOptAC = Optic.expandFieldMatrixAF(mOpt);
    end
    function [mOptAC, mOpt] = getFieldMatrix01(obj, pos, vBasis, par)
      % getFieldMatrixAC method for TEM01 mode
      [mOptAC, mOpt] = getFieldMatrixAC(obj, pos, par);
    end
    function [mOptAC, mOpt] = getFieldMatrix10(obj, pos, vBasis, par)
      % getFieldMatrixAC method for TEM10 mode
      [mOptAC, mOpt] = getFieldMatrixAC(obj, pos, par);
    end
    
    function [mGenAC, mGen] = getGenMatrix(obj, pos, par, varargin)
      % return default expansion of the field matrix
      mCplMany = getDriveMatrix(obj, pos, par, varargin{:});
      
      %%% Expand 3D coupling matrix to mGen
      
      % number of outputs and drives
      NoutRF = obj.Nout * par.Nrf;
      Ndrv = obj.Ndrive;
      
      % fill in the generation matrix
      mGen = zeros(NoutRF, Ndrv);
      vDC = par.vDC;
      for n = 1:Ndrv
        mGen(:, n) = mCplMany(:, :, n) * vDC;
      end
      
      % expand to upper and lower audio SBs
      mGenAC = [mGen; conj(mGen)];
    end
    function [mGenAC, mGen] = getGenMatrix01(obj, pos, par, varargin)
      % return default expansion of the field matrix
      mCplMany = getDriveMatrix01(obj, pos, par, varargin{:});
      
      %%% Expand 3D coupling matrix to mGen
      
      % number of outputs and drives
      NoutRF = obj.Nout * par.Nrf;
      Ndrv = obj.Ndrive;
      
      % fill in the generation matrix
      mGen = zeros(NoutRF, Ndrv);
      vDC = par.vDC;
      for n = 1:Ndrv
        mGen(:, n) = mCplMany(:, :, n) * vDC;
      end
      
      % expand to upper and lower audio SBs
      mGenAC = [mGen; conj(mGen)];
    end
    function [mGenAC, mGen] = getGenMatrix10(obj, pos, par, varargin)
      % return default expansion of the field matrix
      mCplMany = getDriveMatrix10(obj, pos, par, varargin{:});
      
      %%% Expand 3D coupling matrix to mGen
      
      % number of outputs and drives
      NoutRF = obj.Nout * par.Nrf;
      Ndrv = obj.Ndrive;
      
      % fill in the generation matrix
      mGen = zeros(NoutRF, Ndrv);
      vDC = par.vDC;
      for n = 1:Ndrv
        mGen(:, n) = mCplMany(:, :, n) * vDC;
      end
      
      % expand to upper and lower audio SBs
      mGenAC = [mGen; conj(mGen)];
    end
    
    function mCpl = getDriveMatrix(obj, pos, par)
      % getDriveMatrix method
      %   returns the default drive coupling matrix: an empty matrix
      %
      % mDrv = getDriveMatrix(obj, pos, par)
      
      mCpl = [];
    end
    function mCpl = getDriveMatrix01(obj, pos, vBasis, par)
      % getDriveMatrix01 method
      %   returns the default drive coupling matrix for TEM01 mode:
      %   just the same matrix as for the TEM00 mode
      
      mCpl = obj.getDriveMatrix(pos, par);
    end
    function mCpl = getDriveMatrix10(obj, pos, vBasis, par)
      % getDriveMatrix10 method
      %   returns the default drive coupling matrix for TEM10 mode:
      %   just the same matrix as for the TEM00 mode
      
      mCpl = obj.getDriveMatrix(pos, par);
    end
    
    function [mRad, mFrc, vRspAF] = getReactMatrix(obj, pos, par)
      % default getReactMatrix method
      %   returns a zero matrix, Ndrive x (Nrf * Nin) x Naf
      %
      % [mRad, mFrc, vRsp] = getReactMatrix(obj, pos, par);
      
      mRad = zeros(obj.Ndrive, 2 * par.Nrf * obj.Nin);
      mFrc = zeros(obj.Ndrive, obj.Ndrive);
      vRspAF = zeros(par.Naf, obj.Ndrive);
      
    end
    function [mRad, mFrc, vRspAF] = getReactMatrix01(obj, pos, par)
      % default getReactMatrix01 method
      %   returns a zero matrix, Ndrive x (Nrf * Nin) x Naf
      %
      % [mRad, mFrc, vRsp] = getReactMatrix01(obj, pos, par);
      
      [mRad, mFrc, vRspAF] = getReactMatrix(obj, pos, par);
      
    end
    function [mRad, mFrc, vRspAF] = getReactMatrix10(obj, pos, par)
      % default getReactMatrix10 method
      %   returns a zero matrix, Ndrive x (Nrf * Nin) x Naf
      %
      % [mRad, mFrc, vRsp] = getReactMatrix10(obj, pos, par);
      
      [mRad, mFrc, vRspAF] = getReactMatrix(obj, pos, par);      
    end

    function mQuant = getNoiseMatrix(obj, pos, par)
      % mQuant = getNoiseMatrix(obj, pos, par)
      %   mQuant is (Nrf * Nout) x Nnoise
      %
      % returns a matrix of noise vectors which correspond to
      % the quantum noises which enter the Optickle system.
      %
      % In this, the default implementation, Nnoise = 0.
      mQuant = zeros(2 * par.Nrf * obj.Nout, 0);
    end
    function mQuant = getNoiseMatrix01(obj, pos, par)
      mQuant = zeros(2 * par.Nrf * obj.Nout, 0);
    end
    function mQuant = getNoiseMatrix10(obj, pos, par)
      mQuant = zeros(2 * par.Nrf * obj.Nout, 0);
    end
    
    function qm = getBasisMatrix(obj)
      % qm = getBasisMatrix(obj)
      %
      % default basis matrix: no basis change
      
      
      qm = repmat(OpHG, obj.Nin, obj.Nout);
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
      obj.pos = pos(:);
    end
    function obj = addPosOffset(obj, pos)
      % add to the position offset for an optic
      %
      % obj = addPosOffset(obj, pos)
      
      if length(pos) ~= obj.Ndrive
        error('%s: drive positions not equal to number of drives (%d ~= %d)', ...
          obj.name, length(pos), obj.Ndrive);
      end
      obj.pos = obj.pos + pos;
    end
    function pos = getPosOffset(obj)
      % get the position offset for an optic
      %
      % pos = getPosOffset(obj)
      
      pos = obj.pos;
    end
    function obj = setMechTF(obj, mechTF, nDOF)
      % obj = setMechTF(obj, mechTF)
      %
      % set the mechanical transfer functions of an optic
      %
      % nDOF = 1 is for position
      % nDOF = 2 is for pitch
      
      
      if nargin < 3
        nDOF = 1;
      end
      
      % switch on DOF
      switch nDOF
        case 1
          obj.mechTF = mechTF;
        case 2
          obj.mechTFpit = mechTF;
        otherwise
          error('nDOF must be 1 or 2, got %d', nDOF)
      end
    end
    
    %%%% Input and Output Indexing %%%%
    
    function [n, np] = getFieldOut(obj, outName)
      % returns the index of an output field
      %
      % n = getFieldOut(obj, outName)
      % outName - output name or port number
      % n - output field index (0 means not connected)
      % np - port number for this output (see getOutputPortNum)
      %
      % Example:
      % [n, np] = getFieldOut(optic, 'fr');
      
      np = getOutputPortNum(obj, outName);  % port number
      n = obj.out(np);					            % link number
    end
    function [n, np] = getFieldIn(obj, inName)
      % returns the index of an input field
      %
      % n = getFieldIn(obj, inName)
      % inName - input name or port number
      % n - input field index (0 means not connected)
      % np - port number for this input (see getInputPortNum)
      %
      % Example:
      % [n, np] = getFieldIn(optic, 'fr');
      
      
      np = getInputPortNum(obj, inName);  % port number
      n = obj.in(np);					            % link number
    end

    function n = getDriveNum(obj, name)
      % returns an input drive number, given the drives's name or number
      %
      % n = getDriveNum(obj, portName)
      %
      % Example:
      % n = getDriveNum(optic, 'fr')
      
      if ischar(name)
        % ==== name is a string, try to match it
        m = [];
        for n = 1:obj.Ndrive
          m = strmatch(name, obj.driveNames{n}, 'exact');
          if ~isempty(m)
            break
          end
        end
        
        if isempty(m)
          error('Invalid drive name "%s" for optic "%s".', name, obj.name)
        end
      elseif isnumeric(name)
        % ==== name is an index, check it
        n = name;
        if n < 1
          error('Drive out of range (%d < 1) for optic "%s".', n, obj.name)
        end
        
        if n > obj.Ndrive
          error('Drive out of range (%d > %d) for optic "%s".', ...
            n, obj.Ndrive, obj.name)
        end
      else
        % ==== name is not a number or a string...
        error('Invalid argument of type %s', class(name));
      end
    end
    function n = getInputPortNum(obj, name)
      % returns an input port number, given the port's name or number
      %
      % n = getInputPortNum(obj, portName)
      %
      % Example:
      % n = getInputPortNum(optic, 'fr')
      
      if ischar(name)
        % ==== name is a string, try to match it
        isMatch = false;
        for n = 1:obj.Nin
          isMatch = any(strcmp(obj.inNames{n}, name));
          if isMatch
            break
          end
        end
        
        if ~isMatch
          error('Invalid input name "%s" for optic "%s".', name, obj.name)
        end
      elseif isnumeric(name)
        % ==== name is an index, check it
        n = name;
        if n < 1
          error('Input out of range (%d < 1) for optic "%s".', n, obj.name)
        end
        
        if n > obj.Nin
          error('Input out of range (%d > %d) for optic "%s".', n, obj.Nin, obj.name)
        end
      else
        % ==== name is not a number or a string...
        error('Invalid argument of type %s', class(name));
      end
      
    end
    function n = getOutputPortNum(obj, name)
      % returns an output port number, given the port's name or number
      %
      % n = getOutputPortNum(obj, portName)
      %
      % Example:
      % n = getOutputPortNum(optic, 'fr')
      
      
      if ischar(name)
        % ==== name is a string, try to match it
        isMatch = false;
        for n = 1:obj.Nout
          % each output has more than one name... check them all
          isMatch = any(strcmp(obj.outNames{n}, name));
          if isMatch
            break
          end
        end
        
        if ~isMatch
          error('Invalid output name "%s" for optic "%s".', name, obj.name)
        end
      elseif isnumeric(name)
        % ==== name is an index, check it
        n = name;
        if n < 1
          error('Output out of range (%d < 1) for optic "%s".', n, obj.name)
        end
        
        if n > obj.Nout
          error('Output out of range (%d > %d) for optic "%s".', n, obj.Nout, obj.name)
        end
      else
        % ==== name is not a number or a string...
        error('Invalid argument of type %s', class(name));
      end
    end

    %%%% Display %%%%
    
    function display(obj)
      str = getDispStr(obj, class(obj));
      disp(str)
    end
    function name = getInputName(obj, inNum)
      % Get the full name for this input port for display purposes.
      %   The name returned is in the format optic_name<-port_name
      %
      % name = getInputName(obj, inNum)
      
      name = [obj.name '<-' obj.inNames{inNum}{1}];
    end
    function name = getOutputName(obj, outNum)
      % Get the full name for this output port for display purposes.
      %   The name returned is in the format optic_name->port_name
      %
      % name = getOutputName(obj, outNum)
      
      name = [obj.name '->' obj.outNames{outNum}{1}];
    end
    function str = getDispStr(obj, typeStr)
      % for use by derived classes for standard display  
      
      % make input string
      if isempty(find(obj.in, 1))
        inStr = 'in: none';
      else
        inStr = 'in:';
        
        for m = 1:obj.Nin
          if obj.in(m)
            inStr = [inStr, sprintf(' %s=%d', obj.inNames{m}{1}, ...
              obj.in(m))];
          end
        end
      end
      
      % make output string
      if isempty(find(obj.out, 1))
        outStr = 'out: none';
      else
        outStr = 'out:';
        for m = 1:obj.Nout
          if obj.out(m)
            outStr = [outStr, sprintf(' %s=%d', obj.outNames{m}{1}, ...
              obj.out(m))];
          end
        end
      end
      
      % make complete string
      str = sprintf('%d)  %s is a %s (%s, %s)', ...
        obj.sn, obj.name, typeStr, inStr, outStr);
    end
    
  end % methods
  
  % methods used for model construction
  methods (Access = {?Optic, ?Optickle})
    function obj = setSN(obj, sn, Ndrive)
      % set the serial number of this optic
      %  This function should only be called from @Optickle/addOptic.
      %
      % obj = setSN(obj, Noptic, Ndrive)
      
      obj.sn = sn;
      obj.drive = Ndrive + (1:obj.Ndrive)';
    end
  end
  
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
      mOptRF = blkdiagN(mOpt, Nrf);
      
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
        blkdiagN(mOpt(1:Nout, 1:Nin), Nrf);
      
      % upper right quadrant (only for non-linear optics)
      mOptAC(NoutRF + (1:NoutRF), (1:NinRF)) = ...
        blkdiagN(mOpt(Nout + (1:Nout), 1:Nin), Nrf);
      
      % lower left quadrant (only for non-linear optics)
      mOptAC(1:NoutRF, NinRF + (1:NinRF)) = ...
        blkdiagN(mOpt(1:Nout, Nin + (1:Nin)), Nrf);
      
      % lower right quadrant
      mOptAC(NoutRF + (1:NoutRF), NinRF + (1:NinRF)) = ...
        blkdiagN(mOpt(Nout + (1:Nout), Nin + (1:Nin)), Nrf);
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
  end  % methods (Static)
  
end % Optic

