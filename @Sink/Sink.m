classdef Sink < Optic
  % Sink is a type of Optic used in Optickle
  %
  % Sinks are used for dumping fields, and for defining detector
  % locations.  They are end points for field propagation and 
  % sources of quantum noise.
  %
  % obj = Sink(name, loss)
  %
  % A sink has 1 input and 1 output.
  % Input:  1, in, fr
  % Output: 1, out, fr
  %
  % ==== Members
  % Optic - base class members
  % loss - fraction of incident power lost going from input to output
  %   Usually this can be left at its default value of 1.  Smaller values
  %   can be used to make attenuators.
  %
  % ==== Functions, those in Optic
  %
  % Example: a sink at the REFL port
  % obj = Sink('REFL');

  properties
      loss = []; % power loss going from input to output
  end
  
  methods
    function obj = Sink(name, varargin)
    % obj = Sink(name, loss)
    %
    % Optical parameters:
    % loss - power loss from input to output (default is 1)
        
    % deal with no arguments
    if nargin == 0
        name = '';
    end

    % build optic (a sink has no drives)
    inNames    = {'in'} ;
    outNames   = {'out'};
    driveNames = {};
    obj@Optic(name, inNames, outNames, driveNames);

    % deal with arguments
    errstr = 'Don''t know what to do with ';	% for argument error messages
    switch( nargin )
    case 0					% default constructor, do nothing
    case {1 2}
      % copy constructor
      %if( isa(arg, class(obj)) )
      %  obj = arg;
      %  return
      %end

      % loss
      args = {1};
      args(1:(nargin-1)) = varargin(1:end);
      
      % store stuff in class
      [obj.loss] = deal(args{:});
      
    otherwise
      % wrong number of input args
      error([errstr '%d input arguments.'], nargin);
    end
    end
  end
end

