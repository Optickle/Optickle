classdef Source < Optic
  % Source is a type of Optic used in Optickle
  %
  % A source illuminates the optics.  The source has some amplitude
  % in each of the RF field componenets present in Optickle.  The
  % Hermite-Gauss basis of the source field is specified by the
  % Rayleigh Range (z0) of the beam, and the distance past the beam
  % waist (z, positive for a waist behind the source).
  %
  % obj = Source(name, vArf, z0, z)
  %
  % A source has no inputs, 1 output, and 2 drives
  % Output: 1, out, fr
  % Drives: none
  %
  % ==== Properties
  % Optic - base class members
  %
  % ==== Methods, those in Optic
  %
  % % Example: a source at the REFL port
  % obj = Source('Laser', [0,0,0,1,0,0,0], 1.5e3, 0);

  properties
    vArf = [];   % RF field componenet amplitude vector
  end
  
  methods
    function obj = Source(varargin)
      
      % uses propagated basis by default
      qxy = [];
      
      % switch on arguments
      errstr = 'Don''t know what to do with ';	% for argument error messages
      switch( nargin )
        case 0					% default constructor, do nothing
          name = 'src';
          vArf = [];
        case 1
          % ==== copy constructor
          error([errstr 'a %s.'], class(arg));
        case 2
          % ==== name, vArf
          [name, vArf] = deal(varargin{:});
        case 4
          % ==== name, vArf, z0, z
          [name, vArf, z0x, zx] = deal(varargin{:});
          qxy = [zx - 1i * z0x, zx - 1i * z0x];
        case 6
          % ==== name, vArf, z0x, zx, z0y, zy
          [name, vArf, z0x, zx, z0y, zy] = deal(varargin{:});
          qxy = [zx - 1i * z0x, zy - 1i * z0y];
          
        otherwise
          % wrong number of input args
          error([errstr '%d input arguments.'], nargin);
      end
      
      % build optic (a source has no inputs)
      outNames = {{'out', 'fr'}};
      
      % call superclass constructor
      obj@Optic(name, {}, outNames, []);
      
      % set vArf and qxy
      obj.vArf = vArf;
      obj.qxy = qxy;
    end
      
    end     % methods
end
