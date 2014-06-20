% backend function for tickle and tickle01
%
% [vDC, mPrb] = tickleDC(opt, pos)
% opt       - Optickle model
% pos       - optic positions (Ndrive x 1, or empty)
%


function [vLen, prbList, mapList, mPhiFrf, vDC, mPrb, mPrbQ] = ...
  tickleDC(opt, pos)

  % === Field Info
  [vFrf, vSrc] = getSourceInfo(opt);
  
  % ==== Sizes of Things
  Nlnk = opt.Nlink;		% number of links
  Nprb = opt.Nprobe;	% number of probes
  Nrf  = length(vFrf);	% number of RF components
  Nfld = Nlnk * Nrf;	% number of RF fields
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Convert to Matrix Form
  %   opt, the Optickle model, is not used after this section
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % link and probe conversion
  [vLen, prbList, mapList, mPhiFrf] = convertLinks(opt);

  % optic conversion
  mOpt = convertOpticsDC(opt, mapList, pos);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % ==== DC Fields and Signals
  % Here, the DC fields for each RF component are evaluated
  % at each field evaluation point (FEP, at each link end).
  %
  % Using the DC fields in vDC, we can now finish the probe
  % matrix Mprb, and with that we can compute the DC signals.
  %
  % For easier use outside this function, the DC fields are
  % reshaped and returned in a matrix fDC, which is Nlnk x Nrf.
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % propagation phase matrix
  mPhi = Optickle.getPhaseMatrix(vLen, vFrf, [], mPhiFrf);

  % compute DC fields
  eyeNfld = speye(Nfld);			% a sparse identity matrix
  vDC = (eyeNfld - (mPhi * mOpt)) \ (mPhi * vSrc);

  % compile system wide probe matrix 
  mPrb = zeros(Nprb, Nfld);
  mPrbQ = zeros(Nprb, Nfld);
  for k = 1:Nprb
    mIn_k = prbList(k).mIn;
    mPrb_k = prbList(k).mPrb;
    
    % conjugate transpose of DC fields on this probe
    vDCinCT = (mIn_k * vDC)';
    
    % compute the row of mPrb for this probe
    %  HACK: transpose of mPrb_k is necessary, but not understood
    mPrb(k, :) = vDCinCT * mPrb_k.' * mIn_k;
    
%     fprintf('\n\n====== Prb %d %f\n', k, opt.probe(k).phase);
%     disp(full(mPrb_k))
%     fprintf('\n\n====== Prb^T %d %s\n', k, opt.probe(k).name);
%     disp(full(mPrb_k.'))
    
    % quad phase signals, for oscillator phase noise
    mPrbQ_k = prbList(k).mPrbQ;
    mPrbQ(k, :) = vDCinCT * mPrbQ_k * mIn_k;
  end
  
end
