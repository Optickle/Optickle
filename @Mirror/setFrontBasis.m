% obj = setFrontBasis(obj, dWaist)
%
% Set the distance from the beam waist to the front
% input of this mirror.  For non-flat mirrors,
% the Rayleigh Range of the input beam is given by
%   z0 = sqrt(dWaist * (1/Chr - dWaist))
% The argument of the sqrt must be positive.
%
% This information need not be set for all mirrors, may not
% be set for mirrors with an angle of incidence not equal
% to zero (aoi ~= 0), and is generally only set for a few
% cavity mirrors.  Setting this for a flat mirror (Chr == 0)
% will result in an error for any value other than 0, and is
% not used in any case (as the beam is not constrained by
% this information).
% 
% for general info about beam specification see beamRW, beamZ0, and cavHG
% for applications in Optickle, see @Optickle/setCavityBasis

function obj = setFrontBasis(obj, dWaist)

  obj.dWaist = dWaist;
