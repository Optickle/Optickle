% [mOscPhase, nMod] = getOscPhaseTF(opt, fDC, sigAC)
%
% Returns an oscillator phase noise matrix from all RFmodulators
% to all probes with matching demodulation frequencies.  The
% drive indices of the RFmodulators are also returned.
%
% %% Example:
% opt = optFP;
% f = logspace(-1, 4, 100);
% [fDC, sigDC, sigAC, mMech] = tickle(opt, [], f);
% [mOscPhase, nMod] = getOscPhaseTF(opt, fDC, sigAC);
% m = [getTF(sigAC, 2:3, nMod), getTF(mOscPhase, 2:3, 1)];
% loglog(f, abs(m))
% legend('I - optical', 'Q - optical', 'I - total', 'Q - total')

function [mOscPhase, nMod] = getOscPhaseTF(opt, fDC, sigAC)

  % tickle like environment
  vDC = fDC(:);
  Nopt = opt.Noptic;		% number of optics
  Nprb = opt.Nprobe;		% number of probes
  Nfld = length(vDC);		% number of RF fields
  Naf = size(sigAC, 3);
  
  %%%%% compute quadrature phase DC outputs
  % (see tickle section "DC Fields and Signals")
  
  % link and probe conversion
  [vLen, prbList] = convertLinks(opt);

  % compile system wide probe matrix and probe shot noise vector
  mPrbQ = sparse(Nprb, Nfld);
  for k = 1:Nprb
    mIn_k = prbList(k).mIn;
    mPrbQ_k = prbList(k).mPrbQ;
    
    vDCin = mIn_k * vDC;
    mPrbQ(k, :) = (mPrbQ_k * conj(vDCin)).' * mIn_k;
  end

  % compute signals (see sigDC in tickle)
  sigQ = real(mPrbQ * vDC) / 2;

  % count RFmodulators
  isaMod = false(Nopt, 1);
  for n = 1:Nopt
    isaMod(n) = isa(opt.optic{n}, 'RFmodulator');
  end
  Nmod = sum(isaMod);
  nMod = find(isaMod);
  
  %%%%% compute osc phase noise TFs
  % loop through RFmodulators
  mOscPhase = zeros(Nprb, Nmod, Naf);
  for n = 1:Nmod
    obj = opt.optic{nMod(n)};
    if isa(obj, 'RFmodulator')
      fMod = obj.fMod;
      nMod = getDriveIndex(opt, nMod(n), 'phase');
      
      % loop through probes, looking for frequency matches
      for m = 1:Nprb
	prb = opt.probe(m);
	df = abs(prb.freq - fMod) / fMod;
	if df < 1e-3
	  % found match
	  mOscPhase(m, n, :) = sigAC(m, nMod(n), :) + sigQ(m);
	end
      end
    end
  end
  