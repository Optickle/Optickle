% Optic
% This is the base class for optics used in Optickle
%
% An optic is a general optical component (mirror, lens, etc.).
% Each type of optic has a fixed number of inputs and outputs,
% and names for each.  The details which characterize a given
% optic are specified in the derived types.
%
% ==== Members
% name, sn = name and serial number of this optic
% Nin, Nout = number of input and output fields
% inNames = cell array of input names (Nin x 1)
% outNames = cell array of output names (Nout x 1)
% in = vector of input link serial numbers (Nin x 1)
% out = vector of output link serial numbers (Nout x 1)
% qxy = vector of output basis parameters for X and Y (Nout x 2)
% Ndrive = number of drive inputs
% driveNames = cell array of drive names (Ndrive x 1)
% drive = vector of drive indices (Ndrive x 1)
% pos - static position offset (see setPosOffset)
% mechTF - reaction transfer functions
%   This matrix of transfer-funtions should take radiation pressure
%   as its first input, and give position as its first
%   output (m/N).  If specified, the second and third inputs
%   should be radiation torques around the X and Y axes, and
%   the outputs are rotations around the same axes (pitch and
%   yaw) with units of rad/(N m). (see setMechTF)
%
% ==== Functions
% getFieldIn - the index of an input field at some port
% getFieldOut - the index of an output field at some port
%
% getInputPortNum - the number of an input port, given its name
% getOutputPortNum - the number of an output port, given its name
%
% getInputName - display name for some input port
% getOutputName - display name for some output port
%
% ==== Derived Class Required Functions
% getFieldMatrix - input to output field matrix (Nout*Nrf x Nin*Nrf)
% getBasisMatrix - input to output HG basis transform matrix (Nout x Nin)
%
% getDriveMatrix - drive to output audio side-band matrix,
%   given DC fields (Nout*Nrf x Ndrive)
% getReactMatrix - input audio side-band to drive matrix,
%   given DC fields (Ndrive x Nin*Nrf)  (defaults to all zeros)
%
% obj = Optic;
% obj = Optic(name, inNames, outNames, driveNames);


function obj = Optic(varargin)

  obj = struct('sn', 0, 'name', [], ...
    'Nin', 0, 'Nout', 0, 'inNames', [], 'outNames', [], ...
    'in', [], 'out', [], 'qxy', [], ...
    'Ndrive', 0, 'driveNames', [], 'drive', [], ...
    'pos', [], 'mechTF', []);

  obj.inNames = {};  % do this here because {} in struct is bad
  obj.outNames = {};
  obj.driveNames = {};
  obj = class(obj, 'Optic');

  errstr = 'Don''t know what to do with ';	% for argument error messages
  switch( nargin )
    case 0					% default constructor, do nothing
    case 1
      % copy constructor
      arg = varargin{1};
      if( isa(arg, class(obj)) )
        obj = arg;
      else
        error([errstr 'a %s.'], class(arg));
      end
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
