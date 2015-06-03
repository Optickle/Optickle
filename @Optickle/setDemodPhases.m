function [opt,fDC,sigDC,sigAC,iqPhase] = setDemodPhases(opt,mIQ,mDOF,pos,f0)
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
    % fDC      - DC fields at this position (Nlink x Nrf)
    %            where Nlink is the number of links, and Nrf
    %            is the number of RF frequency components.
    % sigDC    - DC signals for each probe (Nprobe x 1)
    %            where Nprobe is the number of probes.
    % sigAC    - transfer matrix (Nprobe x Ndrive x Naf),
    %            where Ndrive is the total number of optic drive
    %            inputs (e.g., 1 for a mirror, 2 for a RFmodulator).
    %            Thus, sigAC is arranged such that sigAC(n, m, :)
    %            is the TF from the drive m to probe n.
    % iqPhase  - 2 x nProbe array. The first row is the new phases (in deg) of
    %            each maximized quadrature of the nth probe (corresponding to
    %            the third column of mIQ -- the opposite quadrature is 90 deg
    %            away). The second row is the signal ratio after tuning, with
    %            the maximized quadtrature as the numerator.
    %
    % For open loop calculations, one uses "getTF" on "sigAC" -- the output of
    % tickle (instead of "pickleTF" on "results" -- the output of lentickle).
    %
    % $Id: setDemodPhases.m,v 1.4 2011/08/02 18:26:16 nsmith Exp $

    % Compute the DC signals and TFs on resonance
    
    % speedup for simulink NB
    if exist('cacheFunction','file')==2
        [fDC, sigDC, sigAC] = cacheFunction(@tickle,opt, pos, f0);
    else
        [fDC, sigDC, sigAC] = tickle(opt, pos, f0);
    end
    
    nProbes = size(mIQ,1);
    nOptics = size(mDOF,2);

    iqPhase = zeros(1,nProbes);

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
        switch mIQ{iProbe,3} 
            case 'I' % Maximize the I phase
                dPhase = findBestPhase(signalOptTFi,signalOptTFq); %1
                phase = getProbePhase(opt,iProbeSN);               %2
                tunedPhase = phase + dPhase;                       %3
                opt = setProbePhase(opt,iProbeSN,tunedPhase);      %4
                opt = setProbePhase(opt,qProbeSN,tunedPhase + 90); %5

            case 'Q' % Maximize the Q phase
                dPhase = -1*findBestPhase(signalOptTFq,signalOptTFi);
                phase = getProbePhase(opt,qProbeSN);
                tunedPhase = phase + dPhase;
                opt = setProbePhase(opt,qProbeSN,tunedPhase);
                opt = setProbePhase(opt,iProbeSN,tunedPhase-90);
        end

        iqPhase(iProbe) = tunedPhase;
    end

    if nargout>1

        % Run tickle again, with new demod phases
        [fDC, sigDC, sigAC] = tickle(opt, pos, f0);

        for iProbe = 1:nProbes
            signalOptTFi = 0;
            signalOptTFq = 0;

            iProbeSN = getProbeNum(opt,mIQ{iProbe,1});
            qProbeSN = getProbeNum(opt,mIQ{iProbe,2});

            for iOptic = 1:nOptics
                if mDOF(iProbe,iOptic)
                    signalOptTFi = signalOptTFi + mDOF(iProbe,iOptic) * getTF(sigAC,iProbeSN,iOptic);
                    signalOptTFq = signalOptTFq + mDOF(iProbe,iOptic) * getTF(sigAC,qProbeSN,iOptic);
                end
            end
            switch mIQ{iProbe,3}
                case 'I'
                    iqPhase(2,iProbe) = abs(signalOptTFi / signalOptTFq);
                case 'Q'
                    iqPhase(2,iProbe) = abs(signalOptTFq / signalOptTFi);
            end
        end

    end

end

function [deg, rad]=findBestPhase(pI,pQ)

    % if both pI and pQ are real it returns ~ 180/pi*angle(pI + i pQ)
    % but it also finds the best phase if they are complex


    step=1e-5;
    ph=(0:step:(1-step))*pi;

    y=abs( -sin(ph)*pI + cos(ph)*pQ );

    m=min(y);
    inds=find(y==m);
    ind=inds(1);
    mph=ph(ind);

    mx=cos(mph)*pI + sin(mph)*pQ;

    if(real(mx)<0)
      mph=mph-pi;
    end

    %deg=[180/pi*mph,180/pi*angle(real(pI)+i*real(pQ))];
    deg=180/pi*mph;
    rad = mph;

end







