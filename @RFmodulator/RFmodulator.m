% RFmodulator is a type of Optic used in Optickle
%
% RFmodulators can be used to modulate a beam at RF frequencies.
% The inputs to the modulator 
%
% obj = RFmodulator(name, fMod, aMod)
%
% A modulator has 1 input, 1 output, and 2 drives.
% Input:  1, in
% Output: 1, out
% Drive:
%   1, amp - oscillator amplitude noise
%   2, phase - oscillator phase noise
%
% ==== Members
% Optic - base class members
% vMod - modulation frequencies and amplitudes, Nmod x 2
% Nmod - number of RF modulation frequencies
%
% ==== Functions, those in Optic
%
%% Example: an RF phase modulator, modulation amplitude 0.2
% obj = RFmodulator('RFpm20MHz', 20e6, i * 0.2);
%
%% Example: an RF amplitude modulator
% obj = RFmodulator('RFam20MHz', 20e6, 0.1]);

function obj = RFmodulator(varargin)

  obj = struct('fMod', 0, 'aMod', 0);
  obj = class(obj, 'RFmodulator', Optic);

  errstr = 'Don''t know what to do with ';	% for argument error messages
  switch nargin
    case 0					% default constructor, do nothing
    case 1
      % ==== copy constructor
      arg = varargin{1};
      if( isa(arg, class(obj)) )
        obj = arg;
      else
        error([errstr 'a %s.'], class(arg));
      end
    case 3
      % ==== name, fMod, aMod
      [name, obj.fMod, obj.aMod] = deal(varargin{:});
      
      % build optic
      obj.Optic = Optic(name, {'in'}, {'out'}, {{'amp'}, {'phase'}});
    otherwise
      % wrong number of input args
      error([errstr '%d input arguments.'], nargin);
  end
