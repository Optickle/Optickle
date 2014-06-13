classdef GouyPhase < Optic
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
  % Example: a quick telescope at transmission port
  % obj = GouyPhase('TRAN_GOUY', pi / 2);

  properties
      phi = 0; % Gouy phase in radians, see also setPhase and
                % getPhase
  end
  
  methods
    function obj = GouyPhase(name, varargin)
      % obj = GouyPhase(name, phi)
      %
      % Optical Parameters:
      % phi - Gouy phase (in rad)
      
      % deal with no arguments
      if nargin == 0
        name = '';
      end
      
      % build optic (a sink has no drives)
      inNames    = {'in'} ;
      outNames   = {'out'};
      driveNames = {};
      
      % deal with arguments
      errstr = 'Don''t know what to do with ';	% for argument error messages
      switch( nargin )
        case 0					% default constructor, do nothing
          name = '';
        case 1
          %  copy constructor
          %if( isa(arg, class(obj)) )
          %    obj = arg;
          %    return
          %end
          
          % default phi
          phi_arg = 0;
        case 2
          phi_arg = varargin{1};
          
        otherwise
          % wrong number of input args
          error([errstr '%d input arguments.'], nargin);
      end
      
      % call baseclass constructor
      obj@Optic(name, inNames, outNames, driveNames);
      
      % set phase
      obj.phi = phi_arg;
    end
    
    %%%% Legacy %%%%
    function phi = getPhase(obj)
      % phi = getPhase(obj)
      %   returns the Gouy phase added by this telescope.
      
      phi = obj.phi;
    end
    function obj = setPhase(obj, phi)
      % obj = setPhase(obj, phi)
      %   sets the Gouy phase added by this telescope.
      
      obj.phi = phi;
    end
  end
end
