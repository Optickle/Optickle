% [mOpt, rctList, drvList, mQuant] = convertOptics(opt, mapList, pos, f)
%   tickle internal function, not for direct use
%
% Convert Optics to Matrices
%   mapList is from convertLinks

function [mOptGen, mRadFrc, lResp, mQuant] = convertOpticsAC(opt, mapList, pos, f, vDC)

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
  Nrf  = length(vFrf);    % number of RF components
  Naf  = length(f);				% number of audio frequencies
  Nfld = Nlnk * Nrf;      % number of RF fields
  Narf = 2 * Nfld;        % number of audio fields
  Ndof = Narf + Ndrv;     % number of degrees of freedom
  
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
  %   lResp: mechanical response list                    Naf x Nopt
  %   mQuant: quantum noise matrix                       2Nfld x Nvac?
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % parameters for construction
  par = getOptParam(opt);
  par.Naf = Naf;
  par.vFaf = f;

  % system matrices
  mOptGen = sparse(Narf, Ndof);   % [mOpt, mGen]
  mRadFrc = sparse(Ndrv, Ndof);   % [mRad, mFrc]
  
  lResp = zeros(Naf, Ndrv); % frequency response of each drive

  mQuant = sparse(Ndof, 0);  % quantum noises
  
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
      mInAC = blkdiag(mIn,mIn); % make block diagonal
      mOut = mapList(n).mOut;
      mOutAC = blkdiag(mOut,mOut); % make block diagonal
      mDrv = mapList(n).mDrv;
      
      % mapped version of global vDC (Narf x 1) -> (obj.Nin x 1)
      par.vDC = mIn * vDC; 
      
      %%%% Optic Properties
      [mOpt_n, mGen_n, mRad_n, mFrc_n, lResp_n, mQuant_n] = getMatrices(obj, pos(obj.drive), par);
      
      % for debugging
%       fprintf('\n ===================== %s\n', obj.name)
%       fprintf('\n === mOpt \n')
%       disp(full(mOpt_n(1:obj.Nout*Nrf,1:obj.Nin*Nrf)))
%       if obj.Ndrive > 0
%         fprintf('\n === mGen \n')
%         disp(full(mGen_n(1:obj.Nout*Nrf,:)))
%         fprintf('\n === mRad^T \n')
%         disp(full(mRad_n(:,1:obj.Nin*Nrf).'))
%         fprintf('\n === mFrc \n')
%         disp(full(mFrc_n(:,:)))
%       end
      
      % optical field scatter/generation matrix
      mOptGen = mOptGen + mOutAC * [ mOpt_n * mInAC, mGen_n * mDrv.' ] ;
      
      % optic radiation/force response
      mRadFrc = mRadFrc + mDrv * [ mRad_n * mInAC, mFrc_n * mDrv.' ] ;
      
      % mechanical response list
      lResp = lResp + lResp_n * mDrv.';
      
      % account for unconnected inputs
      isCon = obj.in == 0;
      isConRF = repmat(isCon(:), 2 * Nrf, 1);
      mQuantCon_n = mOpt_n(:, isConRF);  % vacuum from disocnnected inputs
      
      % accumulate noises (removing ones that are zero)
      mQ1 = mOutAC * sparse([mQuant_n, mQuantCon_n]);
      isNonZero = full(any(mQ1, 1));
      mQuant = [mQuant, mQ1(:, isNonZero)];  %#ok<AGROW>
  end
  
%  fprintf('\n\n======== mQuant \n')
%  disp(abs(full(mQuant)))
end
