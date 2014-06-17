classdef Squeezer < Optic
  % Squeezer is a type of Optic used in Optickle
  %
  % Squeezers are declared as follows:   
  % obj = Squeezer (name, lambda, fRF, pol, sqAng, sqdB, antidB, sqzOption = 0)
  % obj = Squeezer (name, lambda, fRF, pol, sqAng, x, escEff, sqzOption = 1)
  %
  % A Squeezer has 1 input and 1 output.
  % Input:  1, in, 
  % Output: 1, out,
  %
  % The user may specify either the level of squeezing and anti-squeezing
  % at the squeezer output (sqzOption=0), or the normalized
  % nonlinear interaction strength and the escape efficiency (sqzOption=1). The
  % parameters which are not provided will be calculated automatically.
  % If sqzOption is set to a value other than
  % 0 or 1, an input of sqdB and antidB is assumed.
  %
  % The squeezer only squeezes one polarization of one RF sideband for one
  % wavelength.  Squeezing multiple DC fields requires multiple squeezers.
  %
  % ==== Members
  % Optic - base class members  
  % lambda - wavelength to be squeezed (uses 1064nm by default)
  % fRF - RF sideband of chosen lambda to be used (Uses 0 by default)
  % pol - polarization of chosen RF sideband to be squeezed (Uses S by
  %   default
  % sqAng - squeezing angle (Uses 0 by default---amplitude squeezing)
  % sqdB - amount of squeezing in dB at OPO output (10 dB by default)
  % antidB - amount of antisqueezing in dB at OPO output (10 dB by default)
  % escEff - escape efficiency (1 by default).
  % x - normalized nonlinear interaction strength
  %     x = sqrt(P_pump/P_thresh) = 1 - 1/sqrt(g) where g is nonlinear gain
  % sqzOption - select inputs for specifying squeezer.
  %
  % Default values [lambda, fRF , pol, sqAng, sqdB, antidB, x, escEff] =
  % [1064e-9, 0, 1, 0, 10, 10, 0.5195, 1]
  % ==== Functions, those in Optic
 

  properties
    lambda = []; %Wavelength
    fRF = []; %RF frequency
    pol =[]; % polarization
    sqAng = []; % squeezing angle
    sqzOption = []; %Bit sets whether squeezing in dB or in x is specified
    nu = []; %frequency of squeezed component
  end
  
  % The properties which determine the level of squeezing are write
  % protected.
  % This prevents the user from modifying one of these variables
  % without recaclulating the others. 
  % the methods setSqueezing and setNLGain should be used to modify these
  % values
  properties(GetAccess = 'public', SetAccess = 'protected')
    sqdB =[]; % level of squeezing exiting the OPO in dB
    antidB = []; %level of antisqueezing exiting the OPO in dB
    x = []; %Normalized nonlinear interaction strength
    escEff= []; %Escape Efficiency 
  end
  
  
  methods
    function obj = Squeezer(name, varargin)
      % obj = Squeezer (name, lambda, fRF, pol, sqAng, sqdB, antidB, sqzOption = 0)
      % obj = Squeezer (name, lambda, fRF, pol, sqAng, x, escEff, sqzOption = 1)
      %
      % Parameters:
      %
      % name - object name
      % lambda - wavelength to be squeezed
      % fRF - RF sideband of chosen lambda to be used
      % pol - polarization of chosen RF sideband to be squeezed
      % sqAng - squeezing angle
      % sqdB - amount of squeezing in dB at OPO output
      % antidB - amount of antisqueezing in dB at OPO output
      % escEff - escape efficiency.
      % x - normalized nonlinear interaction strength
      %     x = sqrt(P_pump/P_thresh) = 1 - 1/sqrt(g) where g is nonlinear gain
      % sqzOption - select inputs for specifying squeezer.
      %
      % Default parameters are:
      %[lambda, fRF , pol, sqAng, sqdB, antidB, sqzOption = 0] =
      % [1064e-9, 0, 1, 0, 10, 10, 0]        
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
      errstr = 'Don''t know what to do with '; % for argument error messages
      switch( nargin )
        case 0					% default constructor, do nothing
        case {1, 2, 3, 4, 5, 8}
          args = {1064e-9, 0, 1, 0, 10, 10, 0};
          args(1:(nargin-1)) = varargin(1:end);
          if nargin==8 
            if cell2mat(varargin(end))==1
              [obj.lambda, obj.fRF, obj.pol, obj.sqAng, obj.x,...
                obj.escEff, obj.sqzOption] = deal(args{1:(nargin-1)});
              %Calculate the level of squeezing and antisqueezing from x and
              %escEff
              obj.sqdB = -20*log10(1-4*obj.x*obj.escEff/(1+obj.x)^2);
              obj.antidB = 20*log10(1+4*obj.x*obj.escEff/(1-obj.x)^2);
            else  
              %The user is inputting the level of squeeizng and antisqueezing
              [obj.lambda, obj.fRF, obj.pol, obj.sqAng, obj.sqdB,...
                obj.antidB, obj.sqzOption] = deal(args{1:(nargin-1)});
              Vs = 10^(-1*obj.sqdB/10); %squeezed quadrature variance
              Va = 10^(obj.antidB/10); %antisqueezed quadrature variance
              %Calculate x and escEff from Vs and Va
              obj.x = (Va-Vs-2*sqrt(-1+Va+Vs-Va*Vs))/(Va+Vs-2);
              obj.escEff = (1-Vs)*(1+obj.x)^2/(4*obj.x);
            end
          else
            % For 5 or fewer user specified inputs
            % By default sqdB and antidB are set to 10 dB
            % x and escEff must be calculated
            [obj.lambda, obj.fRF, obj.pol, obj.sqAng, obj.sqdB, ...
               obj.antidB, obj.sqzOption] = deal(args{:});
            Vs = 10^(-1*obj.sqdB/10); %squeezed quadrature variance
            Va = 10^(obj.antidB/10); %antisqueezed quadrature variance
            %Calculate x and escEff from Vs and Va     
            obj.x = (Va-Vs-2*sqrt(-1+Va+Vs-Va*Vs))/(Va+Vs-2);
            obj.escEff = (1-Vs)*(1+obj.x)^2/(4*obj.x);
          end
          % Calculate squeezed frequency from lambda and fRF
          obj.nu = Optickle.c./obj.lambda + obj.fRF; 
        otherwise
          % wrong number of input args
          error([errstr '%d input arguments.'], nargin);
      end
    end
    
    function obj = setSqueezing(obj, sqdB, antidB)
      % obj = setSqueezing(obj, sqdB, antidB)
      % This function allows the user to change the level of
      % Squeezing (sqdB) and anti-squeezing(antidB) specified in dB
      % These properties are protected and cannot be altered directly.
      % This function modifies the sqdB and antidB properties of Squeezer
      % and recalculates x and escEff.
      
      obj.sqdB = sqdB;
      obj.antidB = antidB;
      obj.sqzOption = 0;           
      Vs = 10^(-1*obj.sqdB/10); %squeezed quadrature variance
      Va = 10^(obj.antidB/10); %antisqueezed quadrature variance
      %Calculate x and escEff from Vs and Va     
      obj.x = (Va-Vs-2*sqrt(-1+Va+Vs-Va*Vs))/(Va+Vs-2);
      obj.escEff = (1-Vs)*(1+obj.x)^2/(4*obj.x);    
    end
    
    function obj = setNLGain(obj, x, escEff)
      %obj = setNLGain(obj, x, escEff)
      % This function allows the user to change the level of 
      % the normalized nonlinear interaction strength obj.x
      % and the escape efficiency obj.escEff.
      % The level of squeezing (obj.sqdB) and antisqueezing (obj.antidB)
      % will be recalculated according to the new values of
      % obj.x and obj.escEff.
      
      obj.x = x;
      obj.escEff = escEff;
      obj.sqzOption = 1;
      %Calculate the level of squeezing and antisqueezing from x and
      %escEff
      obj.sqdB = -20*log10(1-4*obj.x*obj.escEff/(1+obj.x)^2);
      obj.antidB = 20*log10(1+4*obj.x*obj.escEff/(1-obj.x)^2);
    end
  end
end