% [mOpt, rctList, drvList] = convertOptics01(opt, mapList, vBasis, pos, f)
%
% Convert Optics to Matrices for TEM01 propagation
%   mapList is from convertLinks

function [mOpt, rctList, drvList] = ...
  convertOptics01(opt, mapList, vBasis, pos, f)

  % === Argument Handling
  if nargin < 4
    pos = [];
  end
  if nargin < 5
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
  %   copied from convertOptics, modified for TEM 01
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
  
  % build system matrices
  for n = 1:Nopt
    obj = opt.optic{n};
    mIn = mapList(n).mIn;
    mOut = mapList(n).mOut;
    mDOF = mapList(n).mDOF;
    
    %%%% Optic Properties
    vBin = NaN(obj.Nin, 2);
    isInOk = obj.in ~= 0;
    vBin(isInOk, :) = vBasis(obj.in(isInOk), :);
    [mOpt_n, mRct_n, mDrv_n] = getMatrices01(obj, pos(obj.drive), vBin, par);
    
    % check matrices
    if any(~isfinite(mOpt_n))
      error('Bad field matrix for optic %s', obj.name)
    end
    if any(~isfinite(mRct_n))
      error('Bad reaction matrix for optic %s', obj.name)
    end
    if any(~isfinite(mDrv_n))
      error('Bad drive matrix for optic %s', obj.name)
    end
    
    % optical field transfer matrix
    mOpt = mOpt + mOut * mOpt_n * mIn;

    % reaction and drive matrices
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
  end
