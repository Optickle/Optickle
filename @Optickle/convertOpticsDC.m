% [mOpt, rctList, drvList, mQuant] = convertOptics(opt, mapList, pos, f)
%   tickle internal function, not for direct use
%
% Convert Optics to Matrices
%   mapList is from convertLinks

function mOpt = convertOpticsDC(opt, mapList, pos)

  % === Argument Handling
  if nargin < 3
    pos = [];
  end
  if nargin < 4
    f = [];
  end

  % === Field Info
  vFrf = getSourceInfo(opt);
  
  % ==== Sizes of Things
  Nopt = opt.Noptic;			% number of optics
  Ndrv = opt.Ndrive;			% number of drives (internal DOFs)
  Nlnk = opt.Nlink;				% number of links
  Nrf  = length(vFrf);			% number of RF components
  Naf  = length(f);				% number of audio frequencies
  Nfld = Nlnk * Nrf;            % number of RF fields
  
  % default positions
  if isempty(pos)
    pos = zeros(Ndrv, 1);
  elseif length(pos) ~= Ndrv
    error('Number of positions (%d) not equal to number of drives (%d)', ...
      length(pos), Ndrv);
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % ==== Optic to Matrix Conversion
  % This is where the optics are converted from types and parmeters
  % to matrices.  The main loop for this section is over all optics.
  % The map matrices are used to build the system matrices from
  % the Field, Reaction and Drive matrices of individual optics.
  %   -- System Optical Properties --
  %   mOpt: optical transfer matrix      Nfld x Nfld
  %
  % NOTE: changes here must be made also in sweep, which contains
  % an optimized version of the following code.
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % parameters for construction
  par = getOptParam(opt);
  par.Naf = Naf;
  par.vFaf = f;

  % system matrices
  mOpt = sparse(Nfld, Nfld);
  
  % build system matrices
  for n = 1:Nopt
    obj = opt.optic{n};
    mIn = mapList(n).mIn;
    mOut = mapList(n).mOut;
    
    %%%% Optic Properties
    mOpt_n = getMatrices(obj, pos(obj.drive), par);
    
    % optical field transfer matrix
    mOpt = mOpt + mOut * mOpt_n * mIn;
  end
