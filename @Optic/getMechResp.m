% Get the mechanical response vectors for a given frequency vector
%   currently this only supports one DOF
%
% rsp = getMechResp(obj, f)

function rsp = getMechResp(obj, f)

  Naf = length(f);
  mechTF = obj.mechTF;
  
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
    if prod(size(rsp)) == 1
      % convert scalar to vector
      rsp = ones(Naf, 1) * rsp;
    end
  else
    rsp = squeeze(rsp(1, 1, :));
  end
  
  if length(rsp) ~= Naf
    error('Bad mechTF for %s', obj.Optic.name);
  end
