classdef Optickle < handle
  % Optickle Model
  %
  % opt = Optickle(vFrf, lambda)
  % vFrf - RF frequency components
  % lambda - carrier wave length (default 1064 nm)
  %          or base wavelengths for each RF component
  % pol - polarization for each RF component (default is S)
  %       this is a vector of the same length as vFrf
  %       its values can be 1 for S or 0 for P.
  %      -->  S == 1, P == 0  <--
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
  % Types of optics some common are listed below:
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
    nu = [];       % nu = c  / lambda + fRF = c * k / (2 * pi)
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
      opt.k = 2 * pi * (1 ./ opt.lambda + opt.vFrf / Optickle.c);
      opt.nu = Optickle.c ./ opt.lambda + opt.vFrf;      
    end
    
    %%%% Add Optics %%%%
    
    function [opt, sn] = addBeamSplitter(opt, name, varargin)
      % [opt, sn] = addBeamSplitter(opt, name, aio, Chr, Thr, Lhr, Rar, Lmd, Nmd)
      %
      % ===> Do not waste time with BeamSplitters <===
      % A BeamSplitter is a 4 input, 8 output object designed to be used
      % where fields propagating in opposite directions overlap on the same
      % optic (e.g., in an interferometer).  If you are simply splitting a
      % beam among detectors you need only one input and 2 outputs, so a
      % Mirror object is sufficient, will reduce complexity as it does not
      % have A and B sides, and will save computation time.  Typically, an
      % interferometer simulation requires only a few BeamSplitter objects
      % (e.g., 1), and none of them are in the readout!
      %
      % aio - angle of incidence (in degrees)
      % Chr - curvature of HR surface (Chr = 1 / radius of curvature)
      % Thr - power transmission of HR surface
      % Lhr - power loss on reflection from HR surface
      % Rar - power reflection of AR surface
      % Nmd - refractive index of medium (1.45 for fused silica, SiO2)
      % Lmd - power loss in medium (one pass)
      %
      % see BeamSplitter and Mirror for more information
      
      obj = BeamSplitter(name, varargin{:});
      [opt, sn] = addOptic(opt, obj);
    end
    function [opt, sn] = addGouyPhase(opt, name, varargin)
      % [opt, sn] = addGouyPhase(opt, name, phi)
      %   Add a Gouy phase adjuster to the model.
      %
      % phi - Gouy phase in radians
      %
      % see also GouyPhase and setGouyPhase
      
      obj = GouyPhase(name, varargin{:});
      [opt, sn] = addOptic(opt, obj);
    end
    function [opt, sn] = addMirror(opt, name, varargin)
      % [opt, sn] = addMirror(opt, name, aio, Chr, Thr, Lhr, Rar, Lmd, Nmd)
      %   Add a mirror to the model.
      %
      % aio - angle of incidence (in degrees)
      % Chr - curvature of HR surface (Chr = 1 / radius of curvature)
      % Thr - power transmission of HR suface
      % Lhr - power loss on reflection from HR surface
      % Rar - power reflection of AR surface
      % Nmd - refractive index of medium (1.45 for fused silica, SiO2)
      % Lmd - power loss in medium (one pass)
      %
      % see Mirror for more information
      
      obj = Mirror(name, varargin{:});
      [opt, sn] = addOptic(opt, obj);
    end
    function [opt, sn] = addModulator(opt, name, varargin)
      % [opt, sn] = addModulator(opt, name, cMod)
      %   Add a modulator to the model.
      %
      % name - name of this optic
      % cMod - modulation coefficient (1 for amplitude, i for phase)
      %        this must be either a scalar, which is applied to all RF
      %        field components, or a vector giving coefficients for each
      %        RF field component.
      %
      % Modulators can be used to modulate a beam.  These are not for
      % continuous modulation (i.e., for making RF sidebands), but rather
      % for measuring transfer functions (e.g., for frequency or intensity
      % noise couplings).
      %
      % see Modulator for more information
      
      obj = Modulator(name, varargin{:});
      [opt, sn] = addOptic(opt, obj);
    end
    function [opt, sn] = addRFmodulator(opt, name, fMod, aMod)
      % [opt, sn] = addRFmodulator(opt, name, fMod, aMod)
      %   Add an RF modulator to the model.
      %
      % name - name of this optic
      % fMod - modulation frequency
      % aMod - modulation index (imaginary for phase, real for amplitude)
      %
      % see RFModulator for more information
      
      obj = RFmodulator(name, fMod, aMod);
      [opt, sn] = addOptic(opt, obj);
    end
    function [opt, sn] = addSink(opt, name, varargin)
      % [opt, sn] = addSink(opt, name, loss)
      %   Add a sink to the model.
      %
      % loss - power loss from input to output (default = 1)
      %
      % Sinks can be used as place holders for probes, or as
      % beam attenuators when loss < 1.  See optFP for examples.
      
      obj = Sink(name, varargin{:});
      [opt, sn] = addOptic(opt, obj);
    end
    function [opt, sn] = addSqueezer( opt, name, varargin )
      % [opt, sn] = addSqueezer(opt, name, loss, sqAng, sqdB)
      %
      % Parameters:
      %
      % loss - This represents the escape efficiency of the OPO
      %   (1-loss = escape efficiency)
      % sqAng - squeezing angle
      % sqdB - amount of squeezing in dB with perfect escape efficiency
      %
      % See squeezer for more options
      
      obj = Squeezer(name, varargin{:});
      [opt, sn] = addOptic(opt, obj);
    end
    function [opt, sn] = addTelescope(opt, name, varargin)
      % [opt, sn] = addTelescope(opt, name, f)
      % [opt, sn] = addTelescope(opt, name, f, df)
      %   Add a Telescope to the model.
      %
      % name - name of this optic
      % f - focal length of first lens
      % df - distances from previous lens and lens focal length
      %      for lenses after the first
      %
      % see Telescope for more information
      
      obj = Telescope(name, varargin{:});
      [opt, sn] = addOptic(opt, obj);
    end
    function [opt, sn] = addWaveplate(opt, name, lfw, theta)
      % [opt, sn] = addWaveplate(opt, name, lfw, theta)
      %   Add an waveplate to the model.
      %
      % name - name of this optic
      % lfw - fraction of wave
      % theta - rotation angle
      %
      % see Waveplate for more information
      
      obj = Waveplate(name, lfw, theta);
      [opt, sn] = addOptic(opt, obj);
    end
    
    function [opt, sn] = addOptic(opt, obj)
      % Add a general optic to the model.
      %
      % [opt, sn] = addOptic(opt, obj)
      %
      % This function is generally not used directly.  Use the add functions
      % for specific types of optics instead (e.g., addMirror).
      %
      % see also addBeamSplitter, addMirror, addModulator, addSink, addSource, etc.
      
      % increment optic serial number
      sn = opt.Noptic + 1;
      opt.Noptic = sn;
      
      % add optic with new serial number and drive indices
      opt.optic{sn, 1} = setSN(obj, sn, opt.Ndrive);
      
      % update drive counter
      opt.Ndrive = opt.Ndrive + obj.Ndrive;
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
    function [isMatch, isClose] = isSameFreq(f1, f2)
      % frequency differences for match and close
      matchFreqDiff = 0.1; 
      closeFreqDiff = 100; 
      
      isMatch = abs(f1 - f2) < matchFreqDiff;
      isClose = abs(f1 - f2) < closeFreqDiff;
    end

    function mPhi = getPhaseMatrix(vLen, vFreq, vPhiLinks, mPhiFrf)
      % phase matrix for tickle and sweep
      %
      % mPhi = getPhaseMatrix(vLen, vFreq, [vPhiLinks], [mPhiFrf])
      % vPhiLinks is an additional (positive) phase for each link at all frequencies (Nlink x 1)
      % mPhiFrf is an additional (positive) phase for each RF frequency (Nlink x Nrf)
      %
      % mPhi = getPhaseMatrix(vLen, vFreq, vPhiLinks, mPhiFrf)
      
      Nlink = numel(vLen);
      Nrf = numel(vFreq);
      
      if nargin < 3 || isempty(vPhiLinks)
        vPhiLinks = zeros(Nlink,1);
      end
      
      if nargin < 4 || isempty(mPhiFrf)
        mPhiFrf = zeros(Nlink,Nrf);
      end
      
      v = exp(1i * (vLen(:) * vFreq(:).'...      % WE PUT MINUS FOR NOW
        + repmat(vPhiLinks, 1, Nrf)...
        + mPhiFrf...
        )... % close phases
        ); % close exp
      
      N = numel(v(:));
      mPhi = sparse(1:N, 1:N, v(:), N, N);
    end
  end
  
end      % classdef
