% Optickle Model
%
% opt = Optickle(vFrf, lambda)
% vFrf - RF frequency components
% lambda - carrier wave length (default 1064 nm)
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
% debug - debugging level (not widely used)
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

function opt = Optickle(varargin)


  newLink = struct('sn', 0, 'len', 0, ...
                   'snSource', 0, 'portSource', 0, ...
                   'snSink', 0, 'portSink', 0);

  newProbe = struct('sn', 0, 'name', [], 'nField', 0, ...
                    'freq', 0, 'phase', 0);

  opt = struct('optic', 0, 'Noptic', 0, 'Ndrive', 0, ...
               'link', newLink, 'Nlink', 0, ...
               'probe', newProbe, 'Nprobe', 0, ...
               'snSource', [], 'lambda', 0, ...
               'k', 0, 'vFrf', [], 'c', 0, 'h', 0, ...
               'minQuant', 1e-3, 'debug', 0);
  opt.optic = {};
  opt.h = 6.62606891e-34;			% Plank constant [J*s]
  opt.c = 299792458;				% speed of light [m/s]
  opt.lambda = 1064e-9;             % default wavelength

  opt = class(opt, 'Optickle');

  errstr = 'Don''t know what to do with ';	% for argument error messages
  switch( nargin )
    case 0					% default constructor
    case 1
      arg = varargin{1};

      % copy constructor
      if( isa(arg, class(opt)) )
        opt = arg;
      elseif( isnumeric(arg) )	% modulation vector
        opt.vFrf = arg(:);
      else
        error([errstr 'an argument of type %s.'], class(arg));
      end
    case 2
      % vFrf, lambda
      arg = varargin{1};
      opt.vFrf = arg(:);
      opt.lambda = varargin{2};
    otherwise					% wrong number of input args
      error([errstr '%d input arguments.'], nargin);
  end

  opt.k = 2 * pi / opt.lambda;			% wave number [1/m]
