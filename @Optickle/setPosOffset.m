% opt = setPosOffset(opt, name, pos)
%
% set the position offset of an optic's drive or drives
% name - name or serial number of an optic
% pos - zero position for this optic
%
% Multiple names can be given, along with a vector of
% drive positions.  If the names are omitted, all drive
% positions are set (i.e., pos must be opt.Ndrive x 1).
%
% NOTE: You must ensure that length(pos) is equal to
%       the sum of Ndrive for the named optics!
%
% Example:
% opt = setPosOffset(optFP, 'EX', 1e-12);

function opt = setPosOffset(opt, varargin)

  if isempty(varargin)
    sn = 1:opt.Noptic;
    pos = zeros(opt.Ndrive, 1);
  elseif length(varargin) == 1
    sn = 1:opt.Noptic;
    pos = varargin{1};
  else
    sn = varargin{1};
    pos = varargin{2};
  end
  
  if ischar(sn) || length(sn) == 1
    % a single number or name
    sn = getSerialNum(opt, sn);
    opt.optic{sn} = setPosOffset(opt.optic{sn}, pos);
  elseif iscell(sn)
    % a cell array of numbers or names
    N = length(sn);
    m = 0;
    for n = 1:N
      snn = getSerialNum(opt, sn{n});
      mm = (1:opt.optic{snn}.Ndrive) + m;
      m = opt.optic{snn}.Ndrive + m;
      if m > length(pos)
	Ndrv = length(getPosOffset(opt, sn));
	error('More drives than positions (%d > %d).', Ndrv, length(pos))
      end
      opt.optic{snn} = setPosOffset(opt.optic{snn}, pos(mm));
    end
    if m ~= length(pos)
      error('More positions than drives (%d > %d).', length(pos), m)
    end
  else
    % a vector of numbers
    N = length(sn);
    m = 0;
    for n = 1:N
      snn = getSerialNum(opt, sn(n));
      mm = (1:opt.optic{snn}.Ndrive) + m;
      m = opt.optic{snn}.Ndrive + m;
      if m > length(pos)
	Ndrv = length(getPosOffset(opt, sn));
	error('More drives than positions (%d > %d).', Ndrv, length(pos))
      end
      opt.optic{snn} = setPosOffset(opt.optic{snn}, pos(mm));
    end
    if m ~= length(pos)
      error('More positions than drives (%d > %d).', length(pos), m)
    end
  end
