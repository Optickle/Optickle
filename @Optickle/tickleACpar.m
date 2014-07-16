% backend function for tickle2 (parallel version)
%
% [mOpt, mMech, noiseOpt, noiseMech] = tickleACpar(opt, f, vLen, vPhiGouy, ...
%   mPhiFrf, mPrb, mOptGen, mRadFrc, lResp, mQuant, shotPrb)


function varargout = tickleACpar(opt, f, vLen, vPhiGouy, ...
  mPhiFrf, mPrb, mOptGen, mRadFrc, lResp, mQuant, shotPrb)

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Divide Work
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % minimum number of frequencies to give to a single lab
  numMin = 50;

  % how many paralle workers are out there?
  %  NOTE: numlabs is a similar built-in function, but it doesn't
  %        work for parpool (see doc parpool).
  poolobj = gcp('nocreate');
  if isempty(poolobj)
    poolsize = 0;
  else
    poolsize = poolobj.NumWorkers;
  end

  % decide how many other threads to use
  numAF = numel(f);
  numWorkers = max(min(floor(numAF / numMin) - 1, poolsize), 0);

  % split work by number of labs
  numEach = floor(numAF / (numWorkers + 1));
  numMine = numAF - numEach * numWorkers;
  
  % decide who gets what (indexs in the frequency vector f)
  idxMine = 1:numMine;
  idxWorker = cell(numWorkers, 1);
  for n = 1:numWorkers
    idxWorker{n} = (1:numEach) + (n - 1) * numEach + numMine;
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Evaluate
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % with or without quantum noise?
  if nargout < 3
    numRslt = 2;  % no quantum noise
  else
    numRslt = 4;  % with quantum noise
  end
  
  % start the workers
  for n = 1:numWorkers
    % request evaluation
    rslt(n) = parfeval(poolobj, @tickleAC, numRslt, opt, f(idxWorker{n}), ...
      vLen,  vPhiGouy, mPhiFrf, mPrb, mOptGen, mRadFrc, ...
      lResp(idxWorker{n}, :), mQuant, shotPrb);
  end
  
  % get outputs
  if numRslt == 2
    %%%%%%%%%%%%%%%%%%%%%
    % No Quantum Noise
    %%%%%%%%%%%%%%%%%%%%%
        
    % do local work
    [mOpt, mMech] = tickleAC(opt, f(idxMine), vLen, vPhiGouy, ...
      mPhiFrf, mPrb, mOptGen, mRadFrc, lResp(idxMine, :), mQuant, shotPrb);
  
    % expand result space
    if numAF > numMine
      mOpt(:, :, numAF) = 0;
      mMech(:, :, numAF) = 0;
    end
    
    % collect the results as they become available
    for n = 1:numWorkers
      % fetchNext blocks until next results are available
      [nn, mOptN, mMechN] = fetchNext(rslt);
      mOpt(:, :, idxWorker{nn}) = mOptN;
      mMech(:, :, idxWorker{nn}) = mMechN;
    end
    
    % Build the outputs
    varargout{1} = mOpt;
    varargout{2} = mMech;
  else
    %%%%%%%%%%%%%%%%%%%%%
    % With Quantum Noise
    %%%%%%%%%%%%%%%%%%%%%
    
    % do local work
    [mOpt, mMech, noiseOpt, noiseMech] = tickleAC(opt, f(idxMine), vLen, vPhiGouy, ...
      mPhiFrf, mPrb, mOptGen, mRadFrc, lResp(idxMine, :), mQuant, shotPrb);
  
    % expand result space
    if numAF > numMine
      mOpt(:, :, numAF) = 0;
      mMech(:, :, numAF) = 0;
      noiseOpt(:, numAF) = 0;
      noiseMech(:, numAF) = 0;
    end
    
    % collect the results as they become available
    for n = 1:numWorkers
      % fetchNext blocks until next results are available
      [nn, mOptN, mMechN, noiseOptN, noiseMechN] = fetchNext(rslt);
      mOpt(:, :, idxWorker{nn}) = mOptN;
      mMech(:, :, idxWorker{nn}) = mMechN;
      noiseOpt(:, idxWorker{nn}) = noiseOptN;
      noiseMech(:, idxWorker{nn}) = noiseMechN;
      
      % for debugging
      %fprintf('got %d of %d from worker %d\n', n, numWorkers, nn)
    end
    
    % Build the outputs
    varargout{1} = mOpt;
    varargout{2} = mMech;
    varargout{3} = noiseOpt;
    varargout{4} = noiseMech;
  end
end
