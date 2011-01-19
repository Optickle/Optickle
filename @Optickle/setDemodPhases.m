function [opt,iqPhase] = setDemodPhases(opt,mIQ,mDOF,pos,f0)
% [opt,iqPhase] = setDemodPhases(opt,mIQ,mDOF,pos,f0)
% Measure Sensing Matrix at 1 frequency (f0) to set demod phases
%
% INPUT:
% opt  - optickle object
% mIQ  - an nProbes x 3 cell array that defines the I-phase probe name (or sn)
%        in column 1, the Q-phase probe name in colum 2, and a 'I' or 'Q' in the
%        third column, depending on which you want maximized.
% mDOF - an nProbes x mOptics array of gains that define a particular IFO's
%        degrees of freedom
% pos  - the cavity detuning (for the DARM offset or SRCL detuning
%        phase, and the like)
% f0   - the frequency at which the demod phase is tuned
% 
% OUTPUT:
% opt      - optickle object containing probes with newly tuned demo phases
% iqPhase  - 1 x nProbe array of new phases for each probe (in degrees)
%
%
% For open loop stuff, one uses getTF on sigAC (instead of pickleTF on
% results)
%
% $Id: setDemodPhases.m,v 1.1 2011/01/19 20:09:29 jkissel Exp $

% Compute the DC signals and TFs on resonance
[fDC, sigDC, sigAC] = tickle(opt, pos, f0);

nProbes = size(mIQ,1);
nOptics = size(mDOF,2);

iqPhase = zeroes(1,nProbes);

for iProbe = 1:nProbes % Loop over probes
    signalOptTFi = 0;
    signalOptTFq = 0;
    
    % Cover the user, if mIQ(iProbe,1:2) are probe names instead of serial
    % numbers
    iProbeSN = getProbeNum(opt,mIQ{iProbe,1});
    qProbeSN = getProbeNum(opt,mIQ{iProbe,2});
    
    % Compute the desired degree of freedom
    for iOptic = 1:nOptics
        if mDOF(iProbe,iOptic) % Anything non-zero gets executed
            signalOptTFi = signalOptTFi + mDOF(iProbe,iOptic) * getTF(sigAC,iProbeSN,iOptic);
            signalOptTFq = signalOptTFq + mDOF(iProbe,iOptic) * getTF(sigAC,qProbeSN,iOptic);
        end
    end
    
    % Switch over which phase we want maximized
    switch mIQ(iProbe,3) 
        case {'I'} % Maximize the I phase
            dPhase = findBestPhase(signalOptTFi,signalOptTFq);
            phase = getProbePhase(opt,iProbeSN);
            tunedPhase = phase + dPhase;
            opt = setProbePhase(opt,iProbeSN,tunedPhase);
            opt = setProbePhase(opt,qProbeSN,tunedPhase + 90);
            
        case {'Q'} % Maximize the Q phase
            dPhase = -1*findBestPhase(signalOptTFq,signalOptTFi);
            phase = getProbePhase(opt,qProbeSN);
            tunedPhase = phase + dPhase;
            opt = setProbePhase(opt,qProbeSN,tunedPhase);
            opt = setProbePhase(opt,iProbeSN,tunedPhase - 90);
    end
    
    iqPhase(iProbe) = tunedPhase;
end








