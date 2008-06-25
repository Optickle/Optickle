% name = getOpticName(opt, sn)
%
% Get the name of an optic
%   sn may be a single serial number, a vector, or a cell array

function name = getOpticName(opt, varargin)

  if isempty(varargin)
    sn = 1:opt.Noptic;
  else
    sn = varargin{1};
  end

  if ischar(sn) || length(sn) == 1
    % a single number or name
    sn = getSerialNum(opt, sn);
    name = opt.optic{sn}.name;
  elseif iscell(sn)
    % a cell array of numbers (or names, but why would anyone do that?)
    N = length(sn);
    name = cell(N, 1);
    for n = 1:N
      snn = getSerialNum(opt, sn{n});
      name{n} = opt.optic{snn}.name;
    end
  else
    % an vector of numbers
    N = length(sn);
    name = cell(N, 1);
    for n = 1:N
      snn = getSerialNum(opt, sn(n));
      name{n} = opt.optic{snn}.name;
    end
  end
