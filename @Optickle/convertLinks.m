% [vLen, prbList, mapList] = convertLinks(opt)
%   tickle internal function, not for direct use
%
% Convert Optickle model to links and probes to matrix form
%   and construct input and output maps for optics

function [vLen, prbList, mapList] = convertLinks(opt)

  % === Field Info
  vFrf = getSourceInfo(opt);
  
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
  prbElem = struct('mIn', sparse(Nrf, Nfld), ...
    'mPrb', sparse(Nrf, Nrf), 'mPrbQ', sparse(Nrf, Nrf));
  prbList = repmat(prbElem, Nprb, 1);
  
  % loop over probes
  for k = 1:Nprb
    prb = opt.probe(k);
    phi = exp(1i * pi * prb.phase / 180);
    phi_quad = exp(1i * pi * (prb.phase + 90) / 180);

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
          prbList(k).mPrbQ(m, n) = phi_quad;
        elseif df_m < 1e-3
          prbList(k).mPrb(m, n) = conj(phi);
          prbList(k).mPrbQ(m, n) = conj(phi_quad);
        elseif df_p < 1e3 || df_m < 1e3
          warning(['Demodulation frequency near-miss for probe %s ' ... 
            'with RF components %d and %d.'], getProbeName(opt,k), n, m)
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
  if nargout < 3
    return
  end
  
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

end
