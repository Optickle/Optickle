% [mOpt, rctList, drvList] = convertOptics01(opt, mapList, vBasis,
% pos, f, is10)
%
%   tickle01 internal function, not for direct use
%
% Convert Optics to Matrices for TEM01 propagation
%   mapList is from convertLinks
%
%  is10 is a switch to select yaw (1) or pitch (~=1 or not given)

function [mOptGen, mRadFrc, lResp, mQuant] = ...
    convertOptics01(opt, mapList, vBasis, pos, f, vDC, is10)

  % === Argument Handling
  if nargin < 4
    pos = [];
  end
  if nargin < 5
    f = [];
  end
  if nargin < 6
    is10 = 0;
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
  %   copied from convertOptics, modified for TEM 01
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % parameters for construction
  par = getOptParam(opt);
  par.Naf = Naf;
  par.vFaf = f;
  par.is10 = is10;
  
  % system matrices
  mOptGen = sparse(Narf,Ndrv+Narf);   % [mOpt, mGen]
  mRadFrc = sparse(Ndrv,Ndrv+Narf);   % [mRad, mFrc]
  
  lResp = zeros(Naf,Ndrv); % frequency response of each drive

  mQuant = sparse(Narf, 0);  % quantum noises
  
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
      vBin = NaN(obj.Nin, 2);
      isInOk = obj.in ~= 0;
      vBin(isInOk, :) = vBasis(obj.in(isInOk), :);
      [mOpt_n, mGen_n, mRad_n, mFrc_n, lResp_n, mQuant_n] = getMatrices01(obj, pos(obj.drive), par, vBin);
      
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
