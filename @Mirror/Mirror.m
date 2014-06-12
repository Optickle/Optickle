classdef Mirror < Optic
  % Mirror is a type of Optic used in Optickle
  %
  % The Mirror object can be used for many purposes.  Generally
  % speaking a mirror has 2 inputs and 4 outputs, and can be
  % used for cavity optics, steering mirrors, 2-beam combiners or
  % splitters, etc.  (For mixing 4 beams, see the BeamSplitter class.)
  %
  % The inputs and outputs for a Mirror are:
  %
  % Inputs:
  % 1, fr, HR = front (HR side)
  % 2, bk, AR = back (AR side)
  %
  % Outputs:
  % 1, fr = front
  % 2, bk = back
  % 3, pi = pick-off sampling back input
  % 4, po = pick-off sampling back output
  %
  % Mirror objects are constructed with the following arguments
  % obj = Mirror(name, aio, Chr, Thr, Lhr, Rar, Lmd, Nmd)
  %
  % Optical Paramters:
  % aio - angle of incidence (in degrees)
  % Chr - curvature of HR surface (Chr = 1 / radius of curvature)
  % Thr - power transmission of HR suface
  % Lhr - power loss on reflection from HR surface
  % Rar - power reflection of AR surface
  % Nmd - refractive index of medium (1.45 for fused silica, SiO2)
  % Lmd - power loss in medium (one pass)
  %
  % default optical parameter values are:
  % [aio, Chr, Thr, Lhr, Rar, Lmd,  Nmd]
  % [  0,   0,   0,   0,   0,   0, 1.45]
  %
  % Chr is the mirror "curvature" which is the inverse of the radius
  % of curvature (c = 1/roc = 1/(2 * f), where f is the focal length).
  % Positive curvatures are used for concave, zero for a flat mirror,
  % and negative values for convex mirrors.
  %
  % Note that the three loss mechanisms (Lhr, Rar and Lmd) have default
  % values of zero.  Non-zero values will result in the entrance of
  % vacuum fluctuations, with a corresponding increase in quantum noise,
  % and an increase in time required to compute quantum noise.
  %
  % Example: a curved input mirror with 3km radius and 1% transmission
  % obj = Mirror('ITMX', 0, 1/3e3, 0.01);
  
  properties
    aoi = [];    % angle of incidence (in degrees)
    Chr = [];    % curvature of HR surface (Chr = 1 / radius of curvature)
    Thr = [];    % power transmission of HR suface
    Lhr = [];    % power loss on reflection from HR surface
    Rar = [];    % power reflection of AR surface
    Lmd = [];    % refractive index of medium (1.45 for fused silica, SiO2)
    Nmd = [];    % power loss in medium (one pass)
    dWaist = []; % distance from the front of the mirror to the beam waist
  end
  
  methods
    function obj = Mirror(name, varargin)
      % obj = Mirror(name, aio, Chr, Thr, Lhr, Rar, Lmd, Nmd)
      %
      % Optical Paramters:
      % aio - angle of incidence (in degrees)
      % Chr - curvature of HR surface (Chr = 1 / radius of curvature)
      % Thr - power transmission of HR suface
      % Lhr - power loss on reflection from HR surface
      % Rar - power reflection of AR surface
      % Lmd - power loss in medium (one pass)
      % Nmd - refractive index of medium (1.45 for fused silica, SiO2)
      %
      % default optical parameter values are:
      % [aio, Chr, Thr, Lhr, Rar, Lmd,  Nmd]
      % [  0,   0,   0,   0,   0,   0, 1.45]
      %
      % Several of these parameters (Thr, Lhr, Rar, Lmd)may be
      % specified for each wavelength and polarization.  This is 
      % done by giving an Nx2 or Nx3 matrix instead of a scalar
      % for that parameter, where the first column is the value,
      % the second is the wavelength, and (optionally) the thrid
      % is the polarization.  For example,
      %   Thr = [0.1, 1064e-9; 0.9, 532e-9];
      % could be used to specify a dichroic mirror.  A PBS might
      % specify
      %   Thr = [1e-3, 1064e-9, 1; 0.99, 1064e-9, 0];
      % or a dichroic mirror in a simulation with multiple polarzations
      %   Thr = [0.1, 1064e-9, 1
      %          0.2, 1064e-9, 0
      %          0.9,  532e-9, 1
      %          0.5,  532e-9, 0];
      % Note that the wavelength must be specified, even if all
      % wavelengths used in the simulation are the same.
      %
      % Any wavelengths/polarizations with unspecified values
      % will use the first value specified (e.g., Thr(1, 1)).
      
      % deal with no arguments
      if nargin == 0
        name = '';
      end
      
      % build optic
      inNames = {{'fr' 'HR'}, {'bk' 'AR'}};
      outNames = {{'fr' 'HR'}, {'bk' 'AR'}, {'pi'}, {'po'}};
      driveNames = {'pos'};
      obj@Optic(name, inNames, outNames, driveNames);
      
      % deal with arguments
      errstr = 'Don''t know what to do with ';	% for argument error messages
      switch( nargin )
        case 0					% default constructor, do nothing
        case {1 2 3 4 5 6 7 8}
          % copy constructor
          %if isa(name, class(obj))
          %  obj = name;
          %  return
          %end
          
          % aoi, Chr, Thr, Lhr, Rar, Lmd, Nmd
          args = {0, 0, 0, 0, 0, 0, 1.45};
          args(1:(nargin - 1)) = varargin(1:end);
          
          % store stuff in class
          [obj.aoi, obj.Chr, obj.Thr, obj.Lhr, ...
            obj.Rar, obj.Lmd, obj.Nmd] = deal(args{:});
          
        otherwise
          % wrong number of input args
          error([errstr '%d input arguments.'], nargin);
      end
    end
    
    function [vThr, vLhr, vRar, vLmd] = getVecProperties(obj, lambda, pol)
      % optic parametes as vectors for each field component
      %
      % [vThr, vLhr, vRar, vLmd] = getVecProperties(obj)
      
      vThr = Optickle.mapByLambda(obj.Thr, lambda, pol);
      vLhr = Optickle.mapByLambda(obj.Lhr, lambda, pol);
      vRar = Optickle.mapByLambda(obj.Rar, lambda, pol);
      vLmd = Optickle.mapByLambda(obj.Lmd, lambda, pol);
    end
    
    %%%% Hermite Gauss Basis %%%%

    function qm = getBasisMatrix(obj)
      % Compute basis transform matrix
      %
      % qm = getBasisMatrix(obj)
      qm = planeConvex(OpHG, obj.aoi, obj.Chr, obj.Nmd);
    end
    function qxy = getFrontBasis(obj)
      % qxy = getFrontBasis(obj)
      %
      % Return the complex basis x-y pair for the front input.
      % see also @Mirror/setFrontBasis and @OpHG/apply
      
      if isempty(obj.dWaist) || ~isfinite(obj.dWaist)
        % basis not determined
        qxy = [];
      elseif obj.Chr == 0
        % flat mirror
        if obj.dWaist ~= 0
          error('%s: distance to waist specified for a flat mirror', ...
            obj.Optic.name);
        end
        
        % not wrong, but not helpful either
        qxy = [];
      elseif obj.aoi ~= 0
        % mirror not a normal to beam... too hard, and not very useful
        error('%s: distance to waist specified for angled mirror', ...
          obj.Optic.name);
      else
        % curved mirror with distance specified
        ROC = 1 / obj.Chr;
        z = obj.dWaist;
        z02 = (ROC - z) * z;
        if z02 <= 0
          error(['%s: Unable to match beam waist at distance %g ' ...
            'to mirror with curvature %g.'], obj.Optic.name, z, obj.Chr);
        end
        z0 = sqrt(z02);
        q = z - 1i * z0;
        qxy = [q q];
      end
      
    end
    function obj = setFrontBasis(obj, dWaist)
      % obj = setFrontBasis(obj, dWaist)
      %
      % Set the distance from the beam waist to the front
      % input of this mirror.  For non-flat mirrors,
      % the Rayleigh Range of the input beam is given by
      %   z0 = sqrt(dWaist * (1/Chr - dWaist))
      % The argument of the sqrt must be positive.
      %
      % This information need not be set for all mirrors, may not
      % be set for mirrors with an angle of incidence not equal
      % to zero (aoi ~= 0), and is generally only set for a few
      % cavity mirrors.  Setting this for a flat mirror (Chr == 0)
      % will result in an error for any value other than 0, and is
      % not used in any case (as the beam is not constrained by
      % this information).
      %
      % for general info about beam specification see beamRW, beamZ0, and cavHG
      % for applications in Optickle, see @Optickle/setCavityBasis
      
      obj.dWaist = dWaist;
    end
    
  end  % methods
  
  methods (Static)
    function mNP = getNoiseAmp(Thr, Lhr, Rar, Lmd, phi, in, minQuant)
      % mNP = getNoiseAmp(Thr, Lhr, Rar, Lmd, in, out)
      %
      % This function returns the quantum noise power matrix for
      % a mirror.
      
      
      % zero small losses
      if Lhr < minQuant
        Lhr = 0;
      end
      if Lmd < minQuant
        Lmd = 0;
      end
      if Rar < minQuant
        Rar = 0;
      end
      
      % ==== From getFieldMatrix
      % reflection phases
      frp = exp(1i * phi);
      brp = conj(frp);
      
      % amplitude reflectivities, transmissivities and phases
      hr = -sqrt(1 - Thr - Lhr);			% HR refl
      ht =  sqrt(Thr);				% HR trans
      ar = -sqrt(Rar);				% AR refl
      at =  sqrt(1 - Rar);				% AR trans
      bt =  sqrt(1 - Lmd);				% bulk trans
      
      hrf =  hr * frp;
      hrb = -hr * brp;
      arf =  ar * frp;
      arb = -ar * brp;
      
      % transmission combinations
      hrbt = hrb * bt;
      arbt = arb * bt;
      htbt =  ht * bt;
      atbt =  at * bt;
      tbo = atbt * hrbt;
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Build noise power matrix
      mNP = zeros(4, 0);
      
      if Lhr ~= 0
        % loss at HR surface, front and back side
        mNP1 = zeros(4, 2);
        aNoise = sqrt(Lhr);
        mNP1(1, 1) = aNoise;
        mNP1(:, 2) = [0; atbt; 0; tbo * arbt] * aNoise;
        mNP = [mNP, mNP1];
      end
      
      if Lmd ~= 0
        % loss in medium, from back to front and front to back
        mNP1 = zeros(4, 2);
        aNoise = sqrt(Lmd);
        mNP1(:, 1) = [ht; atbt * hrb; 0; tbo * arbt * hrb] * aNoise;
        mNP1(:, 2) = [0; at; 0; tbo * arb] * aNoise;
        mNP = [mNP, mNP1];
      end
      
      if Rar ~= 0
        % N1 - vacuum input on back of PI (back input pick-off)
        % N2 - vacuum input on back of BK (back output)
        % N3 - vacuum and losses leading to PO (back output pick-off)
        mNP1 = zeros(4, 3);
        mNP1(:, 1) = [htbt * arb; tbo * arb; at;
          tbo * arbt * hrbt * arb];
        mNP1(:, 2) = [0; arb; 0; tbo * at];
        
        % this one is a bit messy...
        Rhr = 1 - Thr - Lhr;
        Tar = 1 - Rar;
        Tmd = 1 - Lmd;
        
        mNP1(4, 3) = sqrt(Rar + Tar * (Lmd + Tmd * (Lhr + Thr + Rhr * Lmd)));
        mNP = [mNP, mNP1];
      else
        % N1 - vacuum for PI
        % N2 - vacuum for PO
        mNP1 = [0; 0; 1; 0];
        mNP2 = [0; 0; 0; 1];
        mNP = [mNP, mNP1, mNP2];
      end
      
      % add power from open inputs
      if in(1) == 0
        mNP1 = [hrf; atbt * ht; 0; tbo * arbt * ht];
        mNP  = [mNP, mNP1];
      end
      
      if in(2) == 0
        mNP1 = [htbt * at; tbo * at; arf; tbo * arbt * hrbt * at];
        mNP = [mNP, mNP1];
      end
    end
  end  % methods (Static)
  
end

