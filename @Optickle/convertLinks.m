% Convert Optickle model to links and probes to matrix form
%   and construct input and output maps for optics
%
% [vLen, prbList, mapList] = convertLinks(opt)

function [vLen, prbList, mapList] = convertLinks(opt)

  % === Field Info
  vFrf = getSourceInfo(opt);
  
  % ==== Sizes of Things
  Nopt = opt.Noptic;			% number of optics
  Ndrv = opt.Ndrive;			% number of drives (internal DOFs)
  Nlnk = opt.Nlink;				% number of links
  Nprb = opt.Nprobe;			% number of probes
  Nrf  = length(vFrf);			% number of RF components
  Nfld = Nlnk * Nrf;            % number of RF fields
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % ==== Link Conversion
  % vDist(n) is the propagation phases-per-frequency
  %   from the input to the output of each link in rad/Hz.
  % vDist is later used to compute propagation phase, as in
  %   mPhi(m, m) = exp(vDist * vFrf(n));
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  lnks = opt.link;
  vLen = 2 * pi  * [lnks.len]' / opt.c;  

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % ==== Probe Conversion
  % This is where the probe matrices are constructed.
  % For each probe, several matrices are computed:
  %   -- Input and Output Maps --
  %   mIn: all fields to input fields               Nrf x Nfld
  %   mPrb: probe's demod mixing matrix             Nrf x Nrf
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % probe list
  prbElem = struct('mPrb', sparse(Nrf, Nrf), 'mIn', sparse(Nrf, Nfld));
  prbList = repmat(prbElem, Nprb, 1);
  
  % loop over probes
  for k = 1:Nprb
    prb = opt.probe(k);
    phi = exp(i * pi * prb.phase / 180);

    % loop over RF components
    for n = 1:Nrf
      % construct input matrix
      prbList(k).mIn(n, prb.nField + Nlnk * (n - 1)) = 1;

      % loop over RF components again to look for demod matches
      for m = 1:Nrf
        df_p = abs(vFrf(m) - vFrf(n) + prb.freq);
        df_m = abs(vFrf(m) - vFrf(n) - prb.freq);
        if df_p < 1e-3 && df_m < 1e-3
          if prb.phase ~= 0
            warning('Non-zero demod phase for DC probe %k ignored.', k)
          end
          prbList(k).mPrb(m, n) = 2;
        elseif df_p < 1e-3
          prbList(k).mPrb(m, n) = phi;
        elseif df_m < 1e-3
          prbList(k).mPrb(m, n) = conj(phi);
        elseif df_p < 1 || df_m < 1
          warning(['Demodulation frequency near-miss for probe %d ' ... 
            'with RF components %d and %d.'], k, n, m)
        end
      end
    end
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % ==== Optic Link Maps
  % mIn: all fields to input fields               obj.Nin x Nlnk
  % mOut: output fields to all fields             Nlnk x obj.Nout
  % mDOF: optic interal DOFs to all DOFs          Ndrv x obj.Ndrv
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % system matrices
  mapElem = struct('mIn', [], 'mOut', [], 'mDOF', []);
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

    % drive DOF map
    mDOF = sparse(Ndrv, obj.Ndrive);
    for m = 1:obj.Ndrive
      mDOF(obj.drive(m), m) = 1;
    end
    
    % expand in and out to cover all RF frequencies and store in list
    mapList(n).mIn = blkdiagN(mIn, Nrf);
    mapList(n).mOut = blkdiagN(mOut, Nrf);
    
    % store DOF in list
    mapList(n).mDOF = mDOF;
  end
