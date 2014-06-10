classdef RFModulator < Optic
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
  % % Example: an RF phase modulator, modulation amplitude 0.2
  % obj = RFModulator('RFpm20MHz', 20e6, i * 0.2);
  %
  % % Example: an RF amplitude modulator
  % obj = RFModulator('RFam20MHz', 20e6, 0.1]);
  
  properties
    fMod = 0;    % modulation frequency
    aMod = 1i;   % modulation constant
  end
  
  methods
    function obj = RFModulator(varargin)
      
      errstr = 'Don''t know what to do with ';	% for argument error messages
      switch nargin
        case 0					% default constructor, do nothing
        case 3
          % ==== name, fMod, aMod
          [name, fMod_arg, aMod_arg] = deal(varargin{:});
          
        otherwise
          % wrong number of input args
          error([errstr '%d input arguments.'], nargin);
      end
      
      % build optic
      obj@Optic(name, {'in'}, {'out'}, {{'amp'}, {'phase'}});
      obj.fMod = fMod_arg;
      obj.aMod = aMod_arg;
    end
    
  end        % methods
  
end          % classdef