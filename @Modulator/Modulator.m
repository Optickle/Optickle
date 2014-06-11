classdef Modulator < Optic
  % Modulator is a type of Optic used in Optickle
  %
  % Modulators can be used to modulate a beam.  These are not for
  % continuous modulation (i.e., for making RF sidebands), but rather
  % for measuring transfer functions (e.g., for frequency or intensity
  % noise couplings).
  %
  % obj = Modulator(name, cMod)
  %
  % A modulator has 1 input and 1 output.
  % Input:  1, in
  % Output: 1, out
  %
  % ==== Members
  % Optic - base class members
  % cMod - modulation coefficient (1 for amplitude, i for phase)
  %        this must be either a scalar, which is applied to all RF
  %        field components, or a vector giving coefficients for each
  %        RF field component.
  %          amplitude modulation or noise = 2 * RIN
  %          phase modulation in radians
  % Nmod - length(cMod)
  %
  % ==== Functions, those in Optic
  %
  % Example: an amplitude modulator
  % obj = Modulator('ModAM', 1);
  
  properties
      cMod = []; % modulation coefficient (1 for amplitude, i for phase)
      Nmod = []; % length of cMod (can give coefficients for each
                 % RF component)
  end
  
  methods
    function obj = Modulator(name, varargin)
    % obj = Modulator(name, cMod);
    %
    % Optical parameters:
    % cMod - modulation coefficient
        
    % deal with no arguments
    if nargin ==0
        name = '';
    end
    
    % build optic
    inNames    = {'in'} ;
    outNames   = {'out'};
    driveNames = {'drive'};
    obj@Optic(name, inNames, outNames, driveNames);

    % deal with arguments
    errstr = 'Don''t know what to do with ';	% for argument error messages
    switch( nargin )
      case 0					% default constructor, do nothing
      case {1 2}
        % copy constructor
        %if( isa(arg, class(obj)) )
        %    obj = arg;
        %else
        %    error([errstr 'a %s.'], class(arg));
        %end

        % cMod
        args = {1};
        args(1:(nargin-1)) = varargin(1:end);

        % assign class data
        [obj.cMod] = deal(args{:});
        obj.Nmod   = length(obj.cMod);
        
      otherwise
        % wrong number of input args
        error([errstr '%d input arguments.'], nargin);
    end
    
    end
  end
end
