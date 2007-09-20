% rsp = getMechResp(obj, f, nDOF)
%   get a mechanical response vector for a given frequency vector
%
% nDOF = 1 is for position
% nDOF = 2 is for pitch

function rsp = getMechResp(obj, f, nDOF)

  Naf = length(f);
  
  if nargin < 3
    nDOF = 1;
  end
  
  % switch on DOF
  switch nDOF
    case 1
      mechTF = obj.mechTF;
    case 2
      mechTF = obj.mechTFpit;
    otherwise
      error('nDOF must be 1 or 2, got %d', nDOF)
  end
      
  % dechipher mechanical response
  if isempty(mechTF)
    rsp = 0;
  elseif isa(mechTF, 'LTI') || isa(mechTF, 'lti') || isa(mechTF, 'zpk')
    rsp = freqresp(mechTF, 2 * pi * f);
  elseif isa(mechTF, 'struct')
    rsp = sresp(mechTF, f);
  elseif isa(mechTF, 'double')
    rsp = mechTF;
  end
  
  % make mechanical response a vector of length Naf
  if ndims(rsp) < 3
    % 1 input, 1 output
    if numel(rsp) == 1
      % convert scalar to vector
      rsp = ones(Naf, 1) * rsp;
    end
  else
    rsp = squeeze(rsp(1, 1, :));
  end
  
  if length(rsp) ~= Naf
    error('Bad mechTF DOF %d of %s', nDOF, obj.Optic.name);
  end
