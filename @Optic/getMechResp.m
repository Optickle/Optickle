% rsp = getMechResp(obj, f, nDOF)
%   get a mechanical response vector for a given frequency vector
%
% nDOF = Optickle.tfPos is for position
% nDOF = Optickle.tfPit is for pitch
% nDOF = Optickle.tfYaw is for yaw

function rsp = getMechResp(obj, f, nDOF)

  Naf = length(f);
  
  if nargin < 3
    nDOF = Optickle.tfPos;
  end
  
  % switch on DOF
  switch nDOF
    case Optickle.tfPos
      mechTF = obj.mechTF;
    case Optickle.tfPit
      mechTF = obj.mechTFpit;
    case Optickle.tfYaw
      mechTF = obj.mechTFyaw;
    otherwise
      error('nDOF must be 1, 2 or 3, got %d', nDOF)
  end
      
  % decipher mechanical response
  if isempty(mechTF)
    % Any object who's opto-mechanical transfer function is not set ends up
    % here (and is "taken care of" elsewhere)
    rsp = 0;
  elseif isa(mechTF, 'LTI') || isa(mechTF, 'lti') || isa(mechTF, 'zpk')
    rsp = freqresp(mechTF, 2 * pi * f);
  elseif isa(mechTF, 'struct')
    rsp = sresp(mechTF, f);
  elseif isa(mechTF, 'double')
    rsp = mechTF;
    if length(rsp) ~= Naf
      error(['mechTF vector for DOF %d of %s is not the ' ...
          'same length as the frequency vector'], nDOF, obj.name);
    end
  else
    error('Unknown mechTF for DOF %d of %s', nDOF, obj.name);
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
    error('Bad mechTF DOF %d of %s', nDOF, obj.name);
  end
end
