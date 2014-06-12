classdef Waveplate < Optic
  % Waveplate is a type of Optic used in Optickle
  %
  % Waveplates can be used to alter the polarization state.
  %
  % obj = Waveplate(name, lfw, theta)
  %
  % A waveplate has 1 input and 1 output.
  % Input:  1, in
  % Output: 1, out
  %
  % ==== Members
  % Optic - base class members
  % lfw - list of fraction of wave for the waveplate for each wavelength
  %       (e.g. 0.25 for quarter-waveplate, 0.5 for half-waveplate)
  % theta - rotation angle of the waveplate in degrees
  %
  % ==== Functions, those in Optic
  %
  % Example: an HWP for 1064 nm, QWP for 532 nm at 45 degrees
  % obj = Waveplate('WP1', [0.5, 1064e-9 ; 0.25, 532e-9], 45);
  
  properties
      lfw = []; % fractions of wave
      theta = []; % rotation angle
  end
  
  methods
    function obj = Waveplate(name, varargin)
    % obj = Waveplate(name, lfw, theta);
    %
    % Optical parameters:
    % lfw - fractions of wave
    % theta - rotation angle
        
    % deal with no arguments
    if nargin ==0
        name = '';
    end
    
    % build optic
    inNames    = {'in'} ;
    outNames   = {'out'};
    driveNames = {};
    obj@Optic(name, inNames, outNames, driveNames);

    % deal with arguments
    errstr = 'Don''t know what to do with ';	% for argument error messages
    switch( nargin )
      case 0					% default constructor, do nothing
      case 3
        [name, lfw, theta] = deal(varargin{:});
      otherwise
        % wrong number of input args
        error([errstr '%d input arguments.'], nargin);
    end
    % set lfw and theta
    obj.lfw = lfw;
    obj.theta = theta;
    end
  end
end
