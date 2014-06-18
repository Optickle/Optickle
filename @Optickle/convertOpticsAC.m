% [mOpt, rctList, drvList, mQuant] = convertOptics(opt, mapList, pos, f)
%   tickle internal function, not for direct use
%
% Convert Optics to Matrices
%   mapList is from convertLinks

function [mOptGen, mRadFrc, lResp, mQuant] = ...
  convertOpticsAC(opt, mapList, pos, f, vDC, tfType, vBasis)

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
  par.tfType = tfType;

  % set the quantum scale
  pQuant  = Optickle.h * opt.nu;
  aQuant = sqrt(pQuant);
    
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
    
    % mapped version of vBsis, if needed
    if tfType ~= Optickle.tfPos
      vBin = NaN(obj.Nin, 2);
      isInOk = obj.in ~= 0;
      vBin(isInOk, :) = vBasis(obj.in(isInOk), :);
      
      % pass this in with par
      par.vBin = vBin;
    end
    
    %%%% Optic Properties
    [mOpt_n, mGen_n, mRad_n, mFrc_n, lResp_n, mQuant_n] = getMatrices(obj, pos(obj.drive), par);
    
    % optical field scatter/generation matrix
    mOptGen = mOptGen + mOutAC * [ mOpt_n * mInAC, mGen_n * mDrv.' ] ;
    
    % optic radiation/force response
    mRadFrc = mRadFrc + mDrv * [ mRad_n * mInAC, mFrc_n * mDrv.' ] ;
    
    % mechanical response list
    lResp = lResp + lResp_n * mDrv.';
    
    % account for unconnected inputs
    isNotCon = obj.in == 0;
    isNotConRF = repmat(isNotCon(:), 2 * Nrf, 1);
    mQuantCon_n = mOpt_n(:, isNotConRF);  % vacuum from disocnnected inputs
    mQuantRad_n = mRad_n(:, isNotConRF);  % vacuum from disocnnected inputs
    
    if any(isNotCon)
      % aQuant is Nrfx1. mQuantCon_n is Narf x (Ndiscon * 2 * Nrf)
      Ndiscon = sum(isNotCon);
      aQuantTemp = repmat(aQuant.', Ndiscon, 1);
      aQuantMatrix = diag([aQuantTemp(:); aQuantTemp(:)]);
      
      % scale input noises
      mQuantCon_n = mQuantCon_n * aQuantMatrix;
      mQuantRad_n = mQuantRad_n * aQuantMatrix;
    end
    
    % merge field and mechanical responses
    NoutAC = 2 * obj.Nout * Nrf;
    if size(mQuant_n, 1) == NoutAC
      % mQuant_n does not have mechanical part
      mQopt = mOutAC * [mQuant_n, mQuantCon_n];
      
      % fill in with zeros
      mQrad = [zeros(Ndrv, size(mQuant_n, 2)), mDrv * mQuantRad_n];
    else
      % mQuant_n DOES not have mechanical part
      mQopt = mOutAC * [mQuant_n(1:NoutAC, :), mQuantCon_n];
      
      % use mechanical response from mQuant_n
      mQrad = mDrv * [mQuant_n(NoutAC + (1:obj.Ndrv), :), mQuantRad_n];
    end
    
    % stack field and mechanical parts
    mQ1 = [mQopt; mQrad];
    
    % accumulate noises (removing ones that are zero)
    isNonZero = any(mQ1, 1);
    mQuant = [mQuant, sparse(mQ1(:, isNonZero))];  %#ok<AGROW>

    % for debugging
%     fprintf('\n ===================== %s\n', obj.name)
%     fprintf('\n === mOpt \n')
%     disp(full(mOpt_n(1:obj.Nout*Nrf,1:obj.Nin*Nrf)))
%     if obj.Ndrive > 0
%       fprintf('\n === mGen \n')
%       disp(full(mGen_n(1:obj.Nout*Nrf,:)))
%       fprintf('\n === mRad^T \n')
%       disp(full(mRad_n(:,1:obj.Nin*Nrf).'))
%       fprintf('\n === mFrc \n')
%       disp(full(mFrc_n(:,:)))
%     end
%     fprintf('\n === [mQuant_n, mQuantCon_n] \n')
%     disp(full(abs([mQuant_n, mQuantCon_n])))    
  end
  
%  fprintf('\n\n======== mQuant \n')
%  disp(abs(full(mQuant)))
end
