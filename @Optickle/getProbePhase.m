% phase = getProbePhase(opt, nPrb)
%   returns the phase of a probe or collection of probes

function phase = getProbePhase(opt, varargin)

  if isempty(varargin)
    sn = 1:opt.Nprobe;
  else
    sn = varargin{1};
  end

  if ischar(sn) || length(sn) == 1
    % a single number or name
    sn = getProbeNum(opt, sn);
    phase = opt.probe(sn).phase;
  elseif iscell(sn)
    % a cell array of numbers or names
    N = length(sn);
    phase = zeros(N, 1);
    for n = 1:N
      snn = getProbeNum(opt, sn{n});
      phase(n) = opt.probe(snn).phase;
    end
  else
    % an vector of numbers
    N = length(sn);
    phase = zeros(N, 1);
    for n = 1:N
      snn = getProbeNum(opt, sn(n));
      phase(n) = opt.probe(snn).phase;
    end
  end
  