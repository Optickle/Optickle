% display

function display(opt)

  [vFrf, vArf] = getFieldSource(opt);
  Nprb = opt.Nprobe;				% number of probes
  Nlnk = opt.Nlink;				% number of links
  Nopt = opt.Noptic;				% number of optics
  Ndrv = opt.Ndrive;				% number of optics
  Nrf  = length(vFrf);				% number of RF components

  if Nopt == 0
    disp(sprintf('%s: no optics', inputname(1)))
  else
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ==== Frequencies
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    disp(sprintf('==== %d RF freqiencies', Nrf))
    for n = 1:Nrf
      str = sprintf('%d) %s with amplitude %g', n, ...
                    getFreqStr(vFrf(n)), vArf(n));
      disp(str)
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ==== Optics
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    disp(sprintf('==== %d optics', Nopt))
    for n = 1:Nopt
      opt.optic{n}
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ==== Drive points
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    disp(sprintf('==== %d drive points', Ndrv))
    dNames = getDriveNames(opt);
    dMap   = getDriveMap(opt);
    for n = 1:Ndrv
      str = sprintf('%d) %s drives %s (optic %d, drive index %d)',...
            n,dNames{n},getOpticName(opt,dMap(n,1)),dMap(n,1),dMap(n,2));
      disp(str)
    end
  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ==== Links
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    disp(sprintf('==== %d links', Nlnk))
    for n = 1:Nlnk
      lnk = opt.link(n);
      str = sprintf('%d) %g meters from %s to %s', n, lnk.len, ...
                    getSourceName(opt, n), getSinkName(opt, n));
      disp(str)
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ==== Probes
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    disp(sprintf('==== %d probes', Nprb))
    for n = 1:Nprb
      prb = opt.probe(n);
      if prb.freq == 0
        str = sprintf('%d) %s probes field %d at %s', n, ...
                      prb.name, prb.nField, getFreqStr(prb.freq));
      else
        str = sprintf('%d) %s probes field %d at %s, %g degrees', n, ...
                      prb.name, prb.nField, getFreqStr(prb.freq), prb.phase);
      end
      disp(str)
    end
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ==== getFreqStr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str = getFreqStr(freq)

  % check for non-positive frequencies
  if freq == 0
    str = 'DC';
    return
  elseif freq < 0
    lf = log10(-freq);
  else
    lf = log10(freq);
  end
  
  % make a frequency string
  if lf > 9
    str = sprintf('%g GHz', freq / 1e9);
  elseif lf > 6
    str = sprintf('%g MHz', freq / 1e6);
  elseif lf > 3
    str = sprintf('%g kHz', freq / 1e3);
  else
    str = sprintf('%g Hz', freq);
  end
  
