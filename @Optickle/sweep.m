% Compute DC fields, and DC signals at a collection of positions
%
% [fDC, sigDC] = sweep(opt, pos)
% opt - Optickle model
% pos - optic positions (Ndrive x Npos)
%
% fDC - DC fields at each position (Nlink x Nrf x Npos)
% sigDC - DC signals for each probe (Nprobe x Npos)

function [fDC, sigDC] = sweep(opt, pos)

  % === Field Info
  [vFrf, vSrc] = getSourceInfo(opt);
  
  % ==== Sizes of Things
  Nopt = opt.Noptic;			% number of optics
  Ndrv = opt.Ndrive;			% number of drives (internal DOFs)
  Nlnk = opt.Nlink;				% number of links
  Nprb = opt.Nprobe;			% number of probes
  Nrf  = length(vFrf);			% number of RF components
  Nfld = Nlnk * Nrf;            % number of RF fields
  Npos = size(pos, 2);			% number of position vectors
  
  % check positions
  if size(pos, 1) ~= Ndrv
    error('Number of positions not equal to Ndrive (%d ~= %d).', ...
      size(pos, 1), Ndrv);
  end

  % get start positions
  pos0 = zeros(Ndrv, 1);
  for n = 1:Nopt
    obj = opt.optic{n};
    pos0(obj.drive) = getPosOffset(opt, n);
  end

  % link converstion
  [vLen, prbList, mapList] = convertLinks(opt);
  mPhi = getPhaseMatrix(vLen, vFrf);			% propagation phase matrix

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % main position loop
  sigDC = zeros(Nprb, Npos);
  fDC = zeros(Nlnk, Nrf, Npos);
  
  eyeNfld = speye(Nfld);						% a sparse identity matrix

  for n = 1:Npos
    % add position offsets
    for m = 1:Nopt
      obj = opt.optic{m};
      opt = setPosOffset(opt, m, pos0(obj.drive) + pos(obj.drive, n));
    end

    % optic converstion
    %   TODO: make this more inteligent
    %   pass pos to convertOptics, and do it only when pos changes
    mOpt = convertOptics(opt, mapList, []);

    % compute DC fields
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
