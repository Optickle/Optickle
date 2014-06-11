classdef Squeezer < Optic
  % Squeezer is a type of Optic used in Optickle
  %
  % Squeezers are used to     
  % obj = Squeezer (name, loss, sqAng, sqdB)
  %
  % A Squeezer has 1 input and 1 output.
  % Input:  1, in, 
  % Output: 1, out,
  %
  % ==== Members
  % Optic - base class members
  % loss - This represents the escape efficiency of the OPO 
  %   (1-loss = escape efficiency)
  % sqAng - squeezing angle
  % sqdB - amount of squeezing in dB without losses (ie perfect escape
  %  efficiency)
  % 
  % ==== Functions, those in Optic
  %
  % Example: a sink at the REFL port
  % obj = Sink('REFL');

  properties
    loss = []; % 1-escape efficiency
    sqAng = []; % squeezing angle
    sqdB =[]; % level of squeezing without losses in dB
  end
  
  methods
    function obj = Squeezer(name, varargin)
    % obj = Squeezer(name, loss, sqAng, sqdB)
    %
    % Parameters:
    %
    % loss - This represents the escape efficiency of the OPO 
    %   (1-loss = escape efficiency)
    % sqAng - squeezing angle
    % sqdB - amount of squeezing in dB with perfect escape efficiency
    %
    % Default parameters are:
    % [loss, sqAng, sqdB] = 
    % [1, 0, 10]

        
    % deal with no arguments
    if nargin == 0
        name = '';
    end

    % build optic (a Squeezer has no drives)
    inNames    = {'in'} ;
    outNames   = {'out'};
    driveNames = {};
    obj@Optic(name, inNames, outNames, driveNames);

    % deal with arguments
    errstr = 'Don''t know what to do with ';	% for argument error messages
    switch( nargin )
      case 0					% default constructor, do nothing
      case {1, 2, 3, 4}
        % copy constructor
        %if( isa(arg, class(obj)) )
        %  obj = arg;
        %  return
        %end

        % loss
        args = {1,0,10};
        args(1:(nargin-1)) = varargin(1:end);
      
        % store stuff in class
        [obj.loss, obj.sqAng, obj.sqdB] = deal(args{:});
      
      otherwise
        % wrong number of input args
        error([errstr '%d input arguments.'], nargin);
    end
    end
  end
end