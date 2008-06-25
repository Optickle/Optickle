% [mOscPhase, nDrive] = getOscPhaseTF_DDM(opt, fDC, sigAC)
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

function [mOscPhase, nDrive] = getOscPhaseTF_DDM(opt, fDC, sigAC)

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
  [f1,f2]=guessf1f2(opt);
  mOscPhase = zeros(Nprb, Nmod, Naf);
  for n = 1:Nmod
    obj = opt.optic{nMod(n)};
    if isa(obj, 'RFmodulator')
      fMod = obj.fMod;
      nDrive(n) = getDriveIndex(opt, nMod(n), 'phase');
      
      % loop through probes, looking for frequency matches
      for m = 1:Nprb
	prb = opt.probe(m);
	%df = abs(prb.freq - fMod) / fMod;
	%if df < 1e-3
	  % found match
	  G=getLOCoupling(opt,prb.freq,fMod,f1,f2);
	  %[G,prb.freq/1e6,fMod/1e6]
	  mOscPhase(m, n, :) = sigAC(m, nDrive(n), :) + sigQ(m)*G;
	%end
      end
    end
  end
  
return

% This is a quick-fix to get the right coupling for f2+f1 and f2-f1
% 
function G=getLOCoupling(opt,fProbe,fMod,f1,f2)

  G=0;
  x=[-1,0,1];
  y=x';
  A=[1;1;1]*x*f1 + y*[1,1,1]*f2;
  B=abs(A-fProbe);
  m=min(min(B));
  if m<1e-3
    [ii,jj]=find(B==m);
    if abs(f1-fMod)<1e-3
      G=x(jj);
    elseif abs(f2-fMod)<1e-3
      G=y(ii);
    end
  end

return
  
% need yet another cludge to get f1 and f2
function [f1,f2]=guessf1f2(opt)

  names=getProbeName(opt);
  list=strfind(names,'I1');
  ii=1; while length(list{ii})==0, ii=ii+1; end;
  prb=opt.probe(ii);
  f1=prb.freq;
  list=strfind(names,'I2');
  ii=1; while length(list{ii})==0, ii=ii+1; end;
  prb=opt.probe(ii);
  f2=prb.freq;

return

