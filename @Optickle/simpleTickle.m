% simple version of tickle with reduced calculations

function [sigAC, noiseAC] = simpleTickle(opt, pos, f, driveVector, probe)
  
  % find the probe
  sn = getProbeNum(opt,probe);
  
  warning('Removing probes modifies input Optickle model')

  % remove other probes from optical model
  opt.probe = opt.probe(1:end==sn);
  opt.Nprobe = 1;
    
  [~, ~, fullSigAC, ~, noiseAC] = tickle(opt, pos, f, find(driveVector));
  
  sigAC = zeros(length(f),1);
  for kk = 1:length(f)
      sigAC(kk) = fullSigAC(:,:,1)*nonzeros(driveVector);
  end
  
end