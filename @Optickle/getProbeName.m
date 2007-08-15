% name = getProbeName(opt, sn)
%
% Get the name of a probe
%   sn may be a single serial number, a vector, or a cell array

function name = getProbeName(opt, varargin)

  if isempty(varargin)
    sn = 1:opt.Nprobe;
  else
    sn = varargin{1};
  end

  if isstr(sn) || length(sn) == 1
    % a single number or name
    sn = getProbeNum(opt, sn);
    name = opt.probe(sn).name;
  elseif iscell(sn)
    % a cell array of numbers (or names, but why would anyone do that?)
    N = length(sn);
    name = cell(N, 1);
    for n = 1:N
      snn = getProbeNum(opt, sn{n});
      name{n} = opt.probe(snn).name;
    end
  else
    % an vector of numbers
    N = length(sn);
    name = cell(N, 1);
    for n = 1:N
      snn = getProbeNum(opt, sn(n));
      name{n} = opt.probe(snn).name;
    end
  end
  