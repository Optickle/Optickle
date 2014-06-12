classdef Optickle < handle
  % Optickle Model
  %
  % opt = Optickle(vFrf, lambda)
  % vFrf - RF frequency components
  % lambda - carrier wave length,
  %          or base wavelengths for each RF component (default 1064 nm)
  % pol - polarization for each RF component (default is S)
  %
  % Class fields are:
  %
  % optic - a cell array of optics
  % Noptic - number of optics
  % Ndrive - number of drives (inputs to optics)
  % link - an array of links
  % Nlink - number of links
  % probe - an array of probes
  % Nprobe - number of probes
  % lambda - carrier wave length
  % vFrf - RF frequency components
  % h - Plank constant
  % c - speed of light
  % k - carrier wave-number
  % minQuant - minimum loss considered for quantum noise (default = 1e-3)
  % debug - debugging level (default = 1, set to 0 for no tickle info)
  %
  % Of these, only some can be reference directly.  They are:
  %   Noptic, Ndrive, Nlink, Nprobe, lambda, k, c, h, and debug
  % for others, use access functions.
  %
  % ======== Optics
  % An optic is a general optical component (mirror, lens, etc.).
  % Each type of optic has a fixed number of inputs and outputs
  % and a set of parameters which characterize a given instance.
  % Optics provide names, coupling coefficients, and basis
  % parameters for their input linkts.
  %
  % Types of optics are listed below:
  %   Source - a field source (0 inputs, 1 output)
  %   Sink - a field sink, used for detectors (1 inputs, 0 output)
  %
  %   Modulator - audio frequency phase and amplitude modulation (1 in, 1 out)
  %   RFModulator - RF frequency phase and amplitude modulation (1 in, 1 out)
  %
  %   Mirror - a general curved mirror (2 inputs, 4 outputs)
  %   BeamSplitter - a beam-splitter (4 inputs, 8 outputs)
  %
  %   Telescope - a lense or set of lenses (1 input, 1 output)
  %
  % ======== Links
  % Links are connections between optics.
  %
  % sn = serial number of this link
  % snSource, portSource = serial number and port number of source optic
  % snSink, portSink = serial number and port number of sink (destination)
  % len - the length of the link
  %
  % ======== Probes
  % Probes convert fields to signals.
  %
  % name, sn = name and serial number of this probe
  % nField = index of the sampled field
  % freq = demodulation frequency
  % phase = demodulation phase offset (degrees)
  %
  % % Example, initialize a model with 9MHz RF sidebands
  % opt = Optickle([-9e6, 0, 9e6]);
  %
  % see optFP for a more complete example

  properties (SetAccess = protected)
    Noptic = 0;    % number of optics
    Ndrive = 0;    % number of drives (inputs to optics)
    Nlink = 0;     % number of links
    Nprobe = 0;    % number of probes
    
    optic = {};    % a cell array of optics
    link = [];     % an array of links
    probe = [];    % an array of probes
    snSource = []; % serial numbers of the sources
    
    lambda = [];   % carrier wave lengths
    pol = [];      % polarization of each field component
    vFrf = [];     % RF frequency offsets
    k = [];        % wave-number of each field component (lambda and RF)
  end
  
  % user adjustable parameters
  properties (SetAccess = public)
    minQuant = 1e-3; % minimum loss considered for quantum noise
    debug = 1;       % debugging level (set to 0 for no tickle info)
    sigACunits = 0   % units of response matrix (see above)
  end
  
  properties (Constant)
    h = 6.62606891e-34;   % Plank constant [J*s]
    c = 299792458;        % speed of light [m/s]
  end
  
  methods
    function opt = Optickle(varargin)

      
      newLink = struct('sn', 0, 'len', 0, 'phase', 0, ...
        'snSource', 0, 'portSource', 0, ...
        'snSink', 0, 'portSink', 0);
      
      newProbe = struct('sn', 0, 'name', [], 'nField', 0, ...
        'freq', 0, 'phase', 0);
      
      errstr = 'Don''t know what to do with ';	% for argument error messages
      switch( nargin )
        case 0					% default constructor
        case 1
          arg = varargin{1};
          
          % copy constructor
          if( isa(arg, class(opt)) )
            opt = arg;
          elseif( isnumeric(arg) )	% modulation vector
            % vFrf, lambda = 1064e-9
            [opt.vFrf, opt.lambda, opt.pol] = ...
              Optickle.makeRFvector(arg, 1064e-9, 1);
          else
            error([errstr 'an argument of type %s.'], class(arg));
          end
        case 2
          % vFrf, lambda
          [opt.vFrf, opt.lambda, opt.pol] = ...
            Optickle.makeRFvector(varargin{:}, 1);
        case 3
          % vFrf, lambda, pol
          [opt.vFrf, opt.lambda, opt.pol] = ...
            Optickle.makeRFvector(varargin{:});
        otherwise					% wrong number of input args
          error([errstr '%d input arguments.'], nargin);
      end
      
      % structs?
      opt.link = newLink;
      opt.probe = newProbe;
      
      % wave number [1/m]
      opt.k = 2 * pi * (1 ./ opt.lambda + opt.vFrf / opt.c);
      
    end
  end    % methods
  
  methods (Static)
    function [vFrf, lambda, pol] = makeRFvector(vFrf, lambda, pol)
      
      % make column vectors
      vFrf = vFrf(:);
      lambda = lambda(:);
      pol = pol(:);
      
      % expand single lambda
      if numel(lambda) == 1
        lambda = ones(size(vFrf)) * lambda;
      end
      
      % expand single polarization
      if numel(pol) == 1
        pol = ones(size(vFrf)) * pol;
      end
      
      % check sizes
      if numel(vFrf) ~= numel(lambda)
        error('RF frequency vector and lambda vector size mismatch.')
      end
      
      % check sizes
      if numel(vFrf) ~= numel(pol)
        error('RF frequency vector and polarization vector size mismatch.')
      end
      
    end
    function vecVal = mapByLambda(valByLambda, lambda, pol)
      % map values specified as [value, lambda] pairs
      % to one value for each lambda
      %
      % vecVal = mapByLambda(valByLambda, lambda)
      
      % start with default value
      vecVal = ones(size(lambda)) * valByLambda(1);
      
      % number of pairs and field components
      Npair = size(valByLambda, 1);
      
      % decide how to map these... with pol or without?
      if size(valByLambda, 2) == 2
        % loop over pairs looking for wavelength matches
        for n = 1:Npair
          isMatch = valByLambda(n, 2) == lambda;
          vecVal(isMatch) = valByLambda(n, 1);
        end
      elseif size(valByLambda, 2) == 3
        % loop over pairs looking for wavelength and polarization matches
        for n = 1:Npair
          isMatch = valByLambda(n, 2) == lambda & ...
            valByLambda(n, 3) == pol;
          vecVal(isMatch) = valByLambda(n, 1);
        end
      end        
    end  
  end
  
end      % classdef
