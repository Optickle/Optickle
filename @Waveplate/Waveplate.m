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
  % obj = Waveplate('WP1', [0.5 1064e-9 ; 0.25 532e-9], 45);
  
  properties
      lfw = []; % fractions of wave
      theta = []; % rotation angle
  end
  
  methods
    function obj = Waveplate(varargin)
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
    
    obj@Optic(name, inNames, outNames, driveNames);
    % set lfw and theta
    obj.lfw = lfw;
    obj.theta = theta;
    end
    
    function mOpt = getFieldMatrix(obj, pos, par)
      % getFieldMatrix method
      %   returns a mOpt, the field transfer matrix for this optic
      %
      % mOpt = getFieldMatrix(obj, pos, par)
      
      
      % constants
      Nrf = par.Nrf;
      vNu = par.nu;
      vPol = par.pol;
      
      lfw = obj.lfw;   % list of fraction of wave of the waveplate for each wavelength (e.g. 0.25 for QWP, 0.5 for HWP)
      vfw = Optickle.mapByLambda(lfw,par.lambda);
      theta = obj.theta / 180 * pi;   % rotation angle of the waveplate
      mRot = [cos(theta),sin(theta);-sin(theta),cos(theta)];
      mRotInv = inv(mRot);
      
      % loop over RF components
      mOpt = zeros(Nrf, Nrf);
      for n = 1:Nrf
        for m = 1:Nrf
          % wavenumber differences
          isMatch = Optickle.isSameFreq(vNu(m), vNu(n));
          if isMatch
            % Jones matrix
            mJones = mRotInv * [1,0;0,exp(-1i*2*pi*vfw(n))] * mRot;
            for jj = 1:2
              for kk = 1:2
                if [vPol(n)+1,vPol(m)+1] == [jj,kk]
                  mOpt(n,m) = mJones(jj,kk);
                end
              end
            end
          end
        end
      end
    end
  end
end
