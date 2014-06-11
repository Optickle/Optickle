% Compute DC fields, and DC signals at a collection of positions
%
% [fDC, sigDC] = sweep(opt, pos)
% opt - Optickle model
% pos - optic positions (Ndrive x Npos)
%
% fDC - DC fields at each position (Nlink x Nrf x Npos)
% sigDC - DC signals for each probe (Nprobe x Npos)
%
% see also sweepLinear

function [fDC, sigDC] = sweep(opt, pos)

  % === Field Info
  [vFrf, vSrc] = getSourceInfo(opt);
  
  % ==== Sizes of Things
  Nopt = opt.Noptic;			% number of optics
  Ndrv = opt.Ndrive;			% number of drives (internal DOFs)
  Nlnk = opt.Nlink;			% number of links
  Nprb = opt.Nprobe;			% number of probes
  Nrf  = length(vFrf);			% number of RF components
  Nfld = Nlnk * Nrf;			% number of RF fields
  Npos = size(pos, 2);			% number of position vectors
  
  % check positions
  if size(pos, 1) ~= Ndrv
    error('Number of positions not equal to Ndrive (%d ~= %d).', ...
      size(pos, 1), Ndrv);
  end

  % link converstion
  [vLen, prbList, mapList, mPhiFrf] = convertLinks(opt);
  mPhi = getPhaseMatrix(vLen, vFrf, [], mPhiFrf);	% propagation phase matrix

  % parameters for construction
  par = getOptParam(opt);
  par.Naf = 0;
  
  % get initial optical matrices
  mOptAll = cell(Nopt, 1);
  vDrvAll = cell(Nopt, 1);
  for m = 1:Nopt
    obj = opt.optic{m};
    vDrvAll{m} = obj.drive;   % extracting these makes things much faster

    mOptAll{m} = sparse(mapList(m).mOut * ...
      getFieldMatrix(obj, pos(vDrvAll{m}, 1), par) * mapList(m).mIn);
  end
    
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % main position loop
  sigDC = zeros(Nprb, Npos);
  fDC = zeros(Nlnk, Nrf, Npos);
  
  eyeNfld = speye(Nfld);		% a sparse identity matrix

  for n = 1:Npos
    %%%%% optic converstion (short version of convertOptics)
    mOpt = sparse(Nfld, Nfld);
    
    % look for position change
    if n == 1
      dpos = false(Ndrv, 1);
    else
      dpos = pos(:, n) ~= pos(:, n - 1);
    end
    
    % build optical matrix
    for m = 1:Nopt
      obj = opt.optic{m};
      if any(dpos(vDrvAll{m}))
        mOptAll{m} = sparse(mapList(m).mOut * ...
          getFieldMatrix(obj, pos(vDrvAll{m}, n), par) * mapList(m).mIn);
      end
      mOpt = mOpt + mOptAll{m};
    end

    %%%%% compute DC fields (short version of tickle)
    vDC = (eyeNfld - (mPhi * mOpt)) \ (mPhi * vSrc);

    % compile system wide probe matrix
    mPrb = sparse(Nprb, Nfld);
    for k = 1:Nprb
      mIn_k = prbList(k).mIn;
      mPrb_k = prbList(k).mPrb;

      mPrb(k, :) = (mPrb_k * mIn_k * conj(vDC)).' * mIn_k;
    end

    % compute DC outputs
    sigDC(:, n) = real(mPrb * vDC) / 2;
    fDC(:, :, n) = reshape(vDC, Nlnk, Nrf);
  end
