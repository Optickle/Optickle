% [vLen, prbList, mapList] = convertLinks(opt)
%   tickle internal function, not for direct use
%
% Convert Optickle model to links and probes to matrix form
%   and construct input and output maps for optics

function [vLen, prbList, mapList, mPhiFrf] = convertLinks(opt)

  % === Field Info
  vFrf = getSourceInfo(opt);
  vKrf = opt.k;
  kToF = Optickle.c / (2 * pi); % convert wavenumber to frequency
  
  % ==== Sizes of Things
  Nopt = opt.Noptic;			% number of optics
  Ndrv = opt.Ndrive;			% number of drives (internal DOFs)
  Nlnk = opt.Nlink;				% number of links
  Nprb = opt.Nprobe;			% number of probes
  Nrf  = length(vFrf);			% number of RF components
  Nfld = Nlnk * Nrf;			% number of RF fields
  
  % do a quick sanity check
  if Nlnk == 0
    error('There are no links in this model! (see Optickle)')
  elseif Nprb == 0
    error('There are no probes in this model! (see Optickle)')
  elseif Nrf == 0
    error('There are no RF components in this model! (see Optickle)')
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % ==== Link Conversion
  % vDist(n) is the propagation phases-per-frequency
  %   from the input to the output of each link in rad/Hz.
  % vDist is later used to compute propagation phase, as in
  %   mPhi(m, m) = exp(vDist * vFrf(n));
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  lnks = opt.link;
  vLen = 2 * pi  * [lnks.len]' / Optickle.c;  
  
  % additional phase matrix for each RF frequency
  
  mPhiFrf = zeros(Nlnk,Nrf); % size is Nlink x Nrf

  for jLink = 1:Nlnk
    mPhiFrf(jLink,:) = getRfPhase(opt,lnks(jLink));
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % ==== Probe Conversion
  % This is where the probe matrices are constructed.
  % For each probe, several matrices are computed:
  %   -- Input and Output Maps --
  %   mIn: all fields to input fields               Nrf x Nfld
  %   mPrb: probe's demod mixing matrix             Nrf x Nrf
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % probe list
  prbElem = struct('mIn', sparse(Nrf, Nfld), ...
    'mPrb', sparse(Nrf, Nrf), 'mPrbQ', sparse(Nrf, Nrf));
  prbList = repmat(prbElem, Nprb, 1);
  
  % loop over probes
  for jPrb = 1:Nprb
    prb = opt.probe(jPrb);
    phi = exp(1i * pi * prb.phase / 180) / 2;
    phi_quad = exp(1i * pi * (prb.phase + 90) / 180) / 2;

    % loop over RF components (wave numbers)
    for n = 1:Nrf
      % construct input matrix
      prbList(jPrb).mIn(n, prb.nField + Nlnk * (n - 1)) = 1;

      % loop over RF components (wave numbers) again to look for demod matches
      for m = 1:Nrf
        % only bother with same polarization fields
        if opt.pol(n) == opt.pol(m)
          
          % wave number differences
          df_p = kToF * (vKrf(m) - vKrf(n)) + prb.freq;
          df_m = kToF * (vKrf(m) - vKrf(n)) - prb.freq;
          
          % check for matches
          [isMatch_p, isClose_p] = Optickle.isSameFreq(df_p);
          [isMatch_m, isClose_m] = Optickle.isSameFreq(df_m);
          
          % fill matrix with matches
          if isMatch_p && isMatch_m
            if prb.phase ~= 0
              warning('Non-zero demod phase for DC probe %k ignored.', jPrb)
            end
            prbList(jPrb).mPrb(m, n) = 1;
          elseif isMatch_p
            % upper RF match
            prbList(jPrb).mPrb(m, n) = phi;
            prbList(jPrb).mPrbQ(m, n) = phi_quad;
          elseif isMatch_m
            % lower RF match
            prbList(jPrb).mPrb(m, n) = conj(phi);
            prbList(jPrb).mPrbQ(m, n) = conj(phi_quad);
          elseif isClose_p || isClose_m
            disp([df_p, df_m])
            warning(['Demodulation frequency near-miss for probe %s ' ...
              'with RF components %d and %d.'], getProbeName(opt,jPrb), n, m)
          end
        end
      end
    end
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % ==== Optic Link Maps
  % mIn: all fields to input fields               obj.Nin x Nlnk
  % mOut: output fields to all fields             Nlnk x obj.Nout
  % mDrv: optic interal drives to all drives      Ndrv x obj.Ndrv
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if nargout < 3
    return
  end
  
  % system matrices
  mapElem = struct('mIn', [], 'mOut', [], 'mDrv', []);
  mapList = repmat(mapElem, Nopt, 1);
  
  % build system matrices
  for n = 1:Nopt
    obj = opt.optic{n};
    
    %%%% Input and Output Maps
    % input map
    mIn = sparse(obj.Nin, Nlnk);
    for m = 1:obj.Nin
      if obj.in(m)
        mIn(m, obj.in(m)) = 1;
      end
    end
    
    % output map
    mOut = sparse(Nlnk, obj.Nout);
    for m = 1:obj.Nout
      if obj.out(m)
        mOut(obj.out(m), m) = 1;
      end
    end

    % drive map
    mDrv = sparse(Ndrv, obj.Ndrive);
    for m = 1:obj.Ndrive
      mDrv(obj.drive(m), m) = 1;
    end
    
    % expand in and out to cover all RF frequencies and store in list
    mapList(n).mIn = blkdiagN(mIn, Nrf);
    mapList(n).mOut = blkdiagN(mOut, Nrf);
    
    % store drive maps in list
    mapList(n).mDrv = mDrv;
  end

end

function linkPhiRf = getRfPhase(opt,link)
  % returns 1 x Nrf phase for a given link

  phase = link.phase;
  lambda = opt.lambda;
  Nrf = length(lambda);
  
  smallNumberMeters = 1e-12;
  
  phaseSize = size(phase);
  
  linkPhiRf = zeros(1,Nrf);
  
  % switch on second dimension
  switch phaseSize(2)
    case 0
      % empty phase
    case 1
      % common phase
      linkPhiRf = phase*ones(size(linkPhiRf));
    case 2
      % phase for every lambda
      linkPhiRf = Optickle.mapByLambda(phase, lambda);
      
      % loop through lambda
%       for jRf = 1:Nrf
%         % find the phase of this lambda
%         lamInd = find(abs(phase(:,1)-lambda(jRf))<smallNumberMeters,1);
%         
%         lamPhi = phase(lamInd,2);
%         
%         % now put this phase into the correct RF frequency index
%         linkPhiRf(jRf) = lamPhi;
%       end
  end
end
