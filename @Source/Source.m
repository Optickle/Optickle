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
% ==== Members
% Optic - base class members
%
% ==== Functions, those in Optic
%
%% Example: a source at the REFL port
% obj = Source('Laser', [0,0,0,1,0,0,0], 1.5e3, 0);

function obj = Source(varargin)

  obj = struct('vArf', [], 'qxy', []);
  obj = class(obj, 'Source', Optic);

  errstr = 'Don''t know what to do with ';	% for argument error messages
  switch( nargin )
    case 0					% default constructor, do nothing
    case 1
      % ==== copy constructor
      arg = varargin{1};
      if( isa(arg, class(obj)) )
        obj = arg;
      else
        error([errstr 'a %s.'], class(arg));
      end
    case 2
      % ==== name, vArf
      [name, obj.vArf] = deal(varargin{:});
      
      % build optic (a source has no inputs)
      outNames = {{'out', 'fr'}};
      obj.Optic = Optic(name, {}, outNames, {});
    case 4
      % ==== name, vArf, z0, z
      [name, obj.vArf, z0x, zx] = deal(varargin{:});
      obj.qxy = [zx + i * z0x, zx + i * z0x];
      
      % build optic (a source has no inputs)
      outNames = {{'out', 'fr'}};
      obj.Optic = Optic(name, {}, outNames, []);
    case 6
      % ==== name, vArf, z0x, zx, z0y, zy
      [name, obj.vArf, z0x, zx, z0y, zy] = deal(varargin{:});
      obj.qxy = [zx + i * z0x, zy + i * z0y];
      
      % build optic (a source has no inputs)
      outNames = {{'out', 'fr'}};
      obj.Optic = Optic(name, {}, outNames, []);
    otherwise
      % wrong number of input args
      error([errstr '%d input arguments.'], nargin);
  end
