% [mOpt, rctList, drvList, mQuant] = convertOptics(opt, mapList, pos, f)
%   tickle internal function, not for direct use
%
% Convert Optics to Matrices
%   mapList is from convertLinks

function [mOptGen, mRadFrc, mResp, mQuant] = convertOpticsAC(opt, mapList, pos, f, vDC)

  % === Argument Handling
  if nargin < 3
    pos = [];
  end
  if nargin < 4
    error('No audio frequencies defined');
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
  Narf = 2*Nfld;                % number of audio fields
  
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
  %   mOptGen: optical field scatter/generation matrix   Narf x Ndrv+Narf
  %   mRadFrc: radiation/force reaction matrix           Ndrv x Ndrv+Narf
  %   mResp: mechanical response list                    Naf x Nopt
  %   mQuant: quantum noise matrix                       2?Nfld x Nvac?
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % parameters for construction
  par = getOptParam(opt);
  par.Naf = Naf;
  par.vFaf = f;

  % system matrices
  mOptGen = sparse(Narf,Ndrv+Narf);
  mRadFrc = sparse(Ndrv,Ndrv+Narf);
  
  mResp = zeros(Naf,Nopt);

  mQuant = sparse(Nfld, 0);
  
  % build system matrices
  for n = 1:Nopt
      obj = opt.optic{n};
      
      %%%
      % Mapping Matrices
      %
      % mIn   (obj.Nin*Nrf) x Nfld
      % mOut  Nfld x (obj.Nout*Nrf)
      % mDrv  Ndrv x obj.Ndrv
      
      mIn = mapList(n).mIn;
      mInAC = blockdiag(mIn,mIn); % make block diagonal
      mOut = mapList(n).mOut;
      mOutAC = blockdiag(mOut,mOut); % make block diagonal
      mDrv = mapList(n).mDrv;
      
      %mapped version of global vDC (Narf x 1) -> (obj.Nin x 1)
      par.vDC = mIn * vDC; 
      
      %%%% Optic Properties
      [mOpt_n, mGen_n, mRad_n, mFrc_n, mResp_n, mQuant_n] = getMatrices(obj, pos(obj.drive), par);
      
      % optical field scatter/generation matrix
      mOptGen = mOptGen + mOutAC * [ mOpt_n * mInAC, mGen_n * mDrv.' ] ;
      
      % optic radiation/force response
      mRadFrc = mRadFrc + mDrv * [ mRad_n * mInAC, mFrc_n * mDrv.' ] ;
      
      % mechanical response list
      mResp(:,n) = mResp_n;
      
      % NOT WORKING YET FOR OPTICKLE2?
      
      % accumulate noises (removing ones that are zero)
      mQ1 = mOutAC * sparse(mQuant_n);
      isNonZero = full(any(mQ1, 1));
      mQuant = [mQuant, mQ1(:, isNonZero)];  %#ok<AGROW>
  end
  