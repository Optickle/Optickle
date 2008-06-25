% pos = getPosOffset(opt, name)
%   get the position of optic's drive or drives
% 
% name - name or serial number of an optic
%
% Example:
% getPosOffset(optFP, 'EX')

function pos = getPosOffset(opt, varargin)

  if isempty(varargin)
    sn = 1:opt.Noptic;
  else
    sn = varargin{1};
  end

  if ischar(sn) || length(sn) == 1
    % a single number or name
    sn = getSerialNum(opt, sn);
    pos = getPosOffset(opt.optic{sn});
  elseif iscell(sn)
    % a cell array of numbers
    N = length(sn);
    pos = [];
    for n = 1:N
      snn = getSerialNum(opt, sn{n});
      pos = [pos; getPosOffset(opt.optic{snn})];
    end
  else
    % a vector of numbers
    N = length(sn);
    pos = [];
    for n = 1:N
      snn = getSerialNum(opt, sn(n));
      pos = [pos; getPosOffset(opt.optic{snn})];
    end
  end
