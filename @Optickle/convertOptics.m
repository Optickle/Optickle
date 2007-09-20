% [mOpt, rctList, drvList, mQuant] = convertOptics(opt, mapList, pos, f)
%
% Convert Optics to Matrices
%   mapList is from convertLinks

function [mOpt, rctList, drvList, mQuant] = convertOptics(opt, mapList, pos, f)

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
  %   rctList(n).m: reaction matrix      Ndrv x Nfld (list of Naf)
  %   drvList(n).m: drive matrix         Nfld x Nfld (list of Ndrv)
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

  rctElem = struct('m', sparse(Ndrv, Nfld));
  rctList = repmat(rctElem, Naf, 1);

  drvElem = struct('m', sparse(Nfld, Nfld));
  drvList = repmat(drvElem, Ndrv, 1);

  mQuant = sparse(Nfld, 0);
  
  % build system matrices
  for n = 1:Nopt
    obj = opt.optic{n};
    mIn = mapList(n).mIn;
    mOut = mapList(n).mOut;
    mDOF = mapList(n).mDOF;
    
    %%%% Optic Properties
    [mOpt_n, mRct_n, mDrv_n, mQuant_n] = getMatrices(obj, pos(obj.drive), par);
    
    % optical field transfer matrix
    mOpt = mOpt + mOut * mOpt_n * mIn;

    % reaction and drive matrices (only used in AC computation)
    if Naf > 0
      
      % loop over frequencies
      for m = 1:Naf
        mRct_nm = sparse(mRct_n(:, :, m));
        rctList(m).m = rctList(m).m + mDOF * mRct_nm * mIn;
      end
      
      % loop over drives
      for m = 1:obj.Ndrive
        nDrv = obj.drive(m);
        mDrv_nm = sparse(mDrv_n(:, :, m));
        drvList(nDrv).m = mOut * mDrv_nm * mIn;
      end
      
      % accumulate noises (removing ones that are zero)
      mQ1 = mOut * sparse(mQuant_n);
      isNonZero = full(any(mQ1, 1));
      mQuant = [mQuant, mQ1(:, isNonZero)];  %#ok<AGROW>
    end
  end
