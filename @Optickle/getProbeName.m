% name = getProbeName(opt, sn)
%
% Get the name of a probe
%   sn may be a single serial number, a vector, or a cell array
%
% see also getProbeNum

function name = getProbeName(opt, varargin)

  if isempty(varargin)
    sn = 1:opt.Nprobe;
  else
    sn = varargin{1};
  end

  % check probe serial numbers
  sn = getProbeNum(opt, sn);
  
  % get names
  N = length(sn);
  name = cell(N, 1);
  for n = 1:N
    name{n} = opt.probe(sn(n)).name;
  end
  
  % looptickle doesn't like cells, change by Stefan Ballmer, 2010 Mar 1
  if and(iscell(name),length(name)==1)
    name=name{1};
  end  
end
  
