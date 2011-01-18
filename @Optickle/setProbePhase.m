% opt = setProbePhase(opt, sn, phase)
%   set the (demod) phase of a probe
% 
% opt - optickle model/object
% sn - serial number of a probe
% phase - new phase of this probe (in degrees)

function opt = setProbePhase(opt, sn, phase)

if ischar(sn)
    sn = getProbeNum(opt,sn);
end

opt.probe(sn).phase = phase;