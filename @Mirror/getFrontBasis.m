% qxy = getFrontBasis(obj)
%
% Return the complex basis x-y pair for the front input.
% see also @Mirror/setFrontBasis and @OpHG/apply

function qxy = getFrontBasis(obj)

  if isempty(obj.dWaist) || ~isfinite(obj.dWaist)
    % basis not determined
    qxy = [];
  elseif obj.Chr == 0
    % flat mirror
    if obj.dWaist ~= 0
      error('%s: distance to waist specified for a flat mirror', ...
	obj.Optic.name);
    end
    
    % not wrong, but not helpful either
    qxy = [];
  elseif obj.aoi ~= 0
    % mirror not a normal to beam... too hard, and not very useful
    error('%s: distance to waist specified for angled mirror', ...
      obj.Optic.name);
  else
    % curved mirror with distance specified
    ROC = 1 / obj.Chr;
    z = obj.dWaist;
    z02 = (ROC - z) * z;
    if z02 <= 0
      error(['%s: Unable to match beam waist at distance %g ' ...
	'to mirror with curvature %g.'], obj.Optic.name, z, obj.Chr);
    end
    z0 = sqrt(z02);
    q = z - 1i * z0;
    qxy = [q q];
  end
  
end
