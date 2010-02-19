% [outputData, intervals] = pforfun(FUN, commonData, inputData, configInfo)
%   parallel for-loop over a function call
%
%   FUN = function handle
%   commonData = data used by FUN for all loop iterations
%   inputData = array sliced for each call to FUN,
%               or number of times to call FUN
%   configInfo = configuration struct (optional)
%     .timePerExc = estimate of time required for each loop cycle (execution)
%     .batchTime = target batch execution time (default = 1 second)
%     .batchSize = number of executions per batch ([] for auto)
%     .minBatchSize = minimum number of executions per batch ([] for none)
%     .maxBatchSize = maximum number of executions per batch ([] for none)
%     .Nthread = maxiumum number of threads (workers) to use
%     .enableWaitBar = display a wait bar? {true, false}
%     .nameWaitBar = wait bar name
%
%   outputData = accumulated results of fun
%   intervals = Nx3 array of execution intervals [start, stop, time]
%
% pforfun attempts to use multiple threads to evaluate the argument function
% FUN on all of the specified input data.  This is roughly equivalent to
%
%   for n = 1:numel(inputData)
%     outputData(n) = FUN(commonData, inputData(n));
%   end
%
% Furthermore, FUN itself must be able to loop over an inputData array,
% such that the same result is obtained by the above code as by
%
%   outputData = FUN(commonData, inputData);
%
% This is useful to avoid the overhead associated with function calls.
% That is, if each call to FUN on a single element of inputData is takes
% very little time, it is better to have FUN evaluate an array of inputData
% with each call.  The size of the inputData array passed to FUN is called
% the "batch size", and can be configured with the configInfo struct.
%
% If the batch size is not specified explicitly, it will be determined
% from the "time per execution" estimate and target "batch time".  If
% no time per execution estimate is given (or timePerExc = []), it is
% measured during pforfun execution and the batch size is adjusted dynamically.
% The range of automatically generated batch sizes can be limited by the
% minBatchSize and maxBatchSize settings.
%
% Of course, during parallel execution the requirements are somewhat more
% stringent: calls to FUN over any range of inputData must result in the
% outputData for that range.  That is outputData(n:m) in
%
%   outputData(n:m) = FUN(commonData, inputData(n:m));
%
% must be the same as outputData(n:m) in the previous 2 examples for any
% valid n, m pair.
%
% FUN must also satisfy some "workspace transparency" requirements: no
% globals, or references to other workspaces (e.g., with evalin or assignin).
% Furthermore, FUN has no access to graphical display, though printing to
% the console is supported. (see parfor or spmd for more info)
%
% Example: see example_pforfun

% by Matthew Evans, Feb 2010

function [outputData, intervals] = ...
    pforfun(fun, commonData, inputData, configInfo)
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Validate Arguments
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % input data
  if isvector(inputData)
    Nexc = numel(inputData);
  elseif isnumeric(inputData) && isscalar(inputData)
    Nexc = inputData;
    inputData(1:Nexc, 1) = struct('dummy', []);
  else
    error('inputData must be a vector, or a number')
  end
  
  % config info
  if nargin < 4
    configInfo = struct;
  end
  
  if ~isfield(configInfo, 'timePerExc')
    configInfo.timePerExc = [];   % use time trials for execution time
  elseif configInfo.timePerExc <= 0
      error('timePerExc must be greater than zero.')
  end
  
  if ~isfield(configInfo, 'batchTime')
    configInfo.batchTime = 1;   % 1 second nominal batch execution time
  elseif configInfo.batchTime <= 0
      error('batchTime must be greater than zero.')
  end
  
  if ~isfield(configInfo, 'batchSize')
    configInfo.batchSize = [];    % decide dynamically
  elseif ~isempty(configInfo.batchSize) && ...
      ~iIsIntegerScalar(configInfo.batchSize, 1, Inf)
      error('batchSize must be an integer scalar > 0.')
  end
  
  if ~isfield(configInfo, 'minBatchSize') || isempty(configInfo.minBatchSize)
    configInfo.minBatchSize = 1;    % set minimum to 1
  elseif ~iIsIntegerScalar(configInfo.minBatchSize, 1, Inf)
      error('minBatchSize must be an integer scalar > 0.')
  end
  
  if ~isfield(configInfo, 'maxBatchSize')
    configInfo.maxBatchSize = [];    % decide later
  elseif ~isempty(configInfo.maxBatchSize) && ...
      ~iIsIntegerScalar(configInfo.maxBatchSize, 1, Inf)
      error('maxBatchSize must be an integer scalar > 0.')
  end
  
  if ~isfield(configInfo, 'Nthread') || isempty(configInfo.Nthread)
    configInfo.Nthread = matlabpool('size');    % use pool size
  elseif ~iIsIntegerScalar(configInfo.Nthread, 0, Inf)
      error('Nthread must be an integer scalar >= 0.')
  end

  if ~isfield(configInfo, 'enableWaitBar')
    configInfo.enableWaitBar = false;
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Setup Waitbar
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  if ~configInfo.enableWaitBar
    waitInfo = [];
  else
    if ~isfield(configInfo, 'nameWaitBar')
      configInfo.nameWaitBar = 'Running Parallel Loop';
    elseif ~ischar(configInfo.nameWaitBar)
      error('nameWaitBar must be a string.')
    end
    waitInfo.name = configInfo.nameWaitBar;
    waitInfo.hWaitBar = [];
    waitInfo.tStart = tic;
    waitInfo.tLast = 0;
    waitInfo.Ndone = 0;
    waitInfo.Nexc = Nexc;
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Setup parProcess State Struct
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % fill in configInfo.maxBatchSize
  if isempty(configInfo.maxBatchSize)
    Nworkers = matlabpool('size');
    if Nworkers < 2
      configInfo.maxBatchSize = Nexc;
    else
      configInfo.maxBatchSize = max(configInfo.minBatchSize, ...
        ceil(Nexc / Nworkers));
    end
  end
  
  % fill in batchSize, if timePerExc is given
  if isempty(configInfo.batchSize) && ~isempty(configInfo.timePerExc)
    % make batch size to match nominal batch time
    timePerExc = configInfo.timePerExc;
    batchTime = configInfo.batchTime;
    configInfo.batchSize = ceil(batchTime / timePerExc);
    
    % enforce minium and maximum
    configInfo.batchSize = max(configInfo.minBatchSize, configInfo.batchSize);
    configInfo.batchSize = min(configInfo.maxBatchSize, configInfo.batchSize);
  end
  
  stateInfo.config = configInfo;
  stateInfo.wait = waitInfo;
  stateInfo.input = inputData;
  stateInfo.output = [];
  
  stateInfo.isReady = Nexc > 0;
  stateInfo.base = 0;
  stateInfo.limit = Nexc;
  stateInfo.interval = [];

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Call parProcess
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  processInfo.common = commonData;
  processInfo.fun = fun;
  
  % call parallel_function
  stateInfo = parProcess(@iParFun, @iConsume, @iSupply, ...
    stateInfo, processInfo, configInfo.Nthread);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Clean up
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  outputData = stateInfo.output;
  intervals = stateInfo.interval;
  intervals(:, 1) = intervals(:, 1) + 1; % convert base to start
  
  % close the waitbar
  if configInfo.enableWaitBar
    if ~isempty(stateInfo.wait.hWaitBar)
      pause(0.2)  % pause for effect
      close(stateInfo.wait.hWaitBar);
      drawnow     % make sure waitbar is closed
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% iParFun
%   the data processing function for parProcess
function output = iParFun(processInfo, inputData)
  % measure the cpu time required
  tStart = cputime;
  
  % this is run worker-side... just pass on through
  output.data = processInfo.fun(processInfo.common, inputData);
  
  % include execution time in output
  output.tExc = cputime - tStart;
  
  %fprintf('iParFun(%d data) took %.2fs\n', numel(output.data), output.tExc)  
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% iConsume
%   the data consumption function for parProcess
function stateInfo = iConsume(stateInfo, output, n)
  
  % extract base and limit for this interval
  base = stateInfo.interval(n, 1);
  limit = stateInfo.interval(n, 2);
  
  % if necessary, initilize stateInfo.output with the current data
  if isempty(stateInfo.output)
    stateInfo.output = output.data;
  end
  
  % add the current data to stateInfo.output
  stateInfo.output((base + 1):limit) = output.data;

  % and save the interval execution time
  stateInfo.interval(n, 3) = output.tExc;
  
  % update waitbar
  if stateInfo.config.enableWaitBar
    stateInfo.wait = iUpdateWait(stateInfo.wait, limit - base);
  end
  
  %fprintf('iConsume((%d, %d), (%d %s), %d)\n', base, limit, ...
  %  numel(outputData), class(outputData), n)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% iSupply
%   the data supply function for parProcess
function [stateInfo, inputData] = iSupply(stateInfo)

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % decide on next inerval size
  if ~isempty(stateInfo.config.batchSize)
    batchSize = stateInfo.config.batchSize;
  elseif isempty(stateInfo.interval)
    % start with minimum
    batchSize = stateInfo.config.minBatchSize;
  else
    % determine batch size dynamically, based on the last 100 batches
    nn = find(stateInfo.interval(:, 3) > 0, 100, 'last');
    
    if isempty(nn)
      % keep using minimum
      batchSize = stateInfo.config.minBatchSize;
    else
      % try to match the target batch time
      nEach = stateInfo.interval(nn, 2) - stateInfo.interval(nn, 1);
      tEach = stateInfo.interval(nn, 3) ./ nEach;
      
      % use the mean if there are only a few, otherwise use the median
      if numel(nn) < 4
        timePerExc = mean(tEach);
      else
        timePerExc = median(tEach);
      end
      
      % set the batch size
      batchSize = ceil(stateInfo.config.batchTime / timePerExc);
      
      % enforce minium and maximum
      batchSize = max(batchSize, stateInfo.config.minBatchSize);
      batchSize = min(batchSize, stateInfo.config.maxBatchSize);
    end
  end
    
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % set the next interval
  
  % get current base (number of slices already done)
  if isempty(stateInfo.interval)
    base = stateInfo.base;
  else
    base = stateInfo.interval(end, 2);
  end
  
  % set the limit (last slice to process in this interval)
  limit = base + batchSize;
  if limit > stateInfo.limit
    limit = stateInfo.limit;
    stateInfo.isReady = false;
  end
  
  % record this interval
  % if necessary, initialize the interval array
  %   interval is [base, limit, tExc]
  %   where the execution time is filled in by iConsume
  if isempty(stateInfo.interval)
    stateInfo.interval = [base, limit, 0];
  else
    stateInfo.interval(end + 1, :) = [base, limit, 0];
  end
  
  % make data struct
  inputData = stateInfo.input((base + 1):limit);
  
  %fprintf('iSupply(%d, %d)\n', base, limit)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% iUpdateWait
%   update the wait bar
function waitInfo = iUpdateWait(waitInfo, NdoneNow)
  
  % extract from state struct
  name = waitInfo.name;
  hWaitBar = waitInfo.hWaitBar;
  tStart = waitInfo.tStart;
  tLast = waitInfo.tLast;
  Nexc = waitInfo.Nexc;
  Ndone = waitInfo.Ndone + NdoneNow;
  
  % make time estimate
  tNow = toc(tStart);
  frac = Ndone / Nexc;
  tRem = tNow * (1 / frac - 1);
  
  if tNow > 5 && tNow - tLast > 0.5
    % wait bar string
    str = sprintf('%.0f s used, %.0f s left', tNow, tRem);
    
    % check and update waitbar
    if isempty(hWaitBar)
      % create wait bar if there are at least 10s remaining
      if tRem > 5
        try
          strWB = [str ' (close this window to stop)'];
          hWaitBar = waitbar(frac, strWB, 'Name', name);
          tLast = tNow;
        catch
          % can't make wait bar... use text
          if tNow - tLast > 5
            disp(str)
            tLast = tNow;
          end
        end
      end
    else
      try
        strWB = [str ' (close waitbar to stop)'];
        findobj(hWaitBar);			% error if wait bar closed
        waitbar(frac, hWaitBar, strWB);	% update wait string
        tLast = tNow;
      catch
        error('Wait bar closed by user.  Exiting.')
      end
    end
  end

  % update global
  waitInfo.hWaitBar = hWaitBar;
  waitInfo.tLast = tLast;
  waitInfo.Ndone = Ndone;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check if input is a vector of scalar within the specified bounds.
function valid = iIsIntegerScalar(value, lowerBound, upperBound)
  valid = isnumeric(value) && isreal(value) && isscalar(value) ...
    && (value >= lowerBound) && (value <= upperBound) ...
    && isfinite(value) && (fix(value) == value);
end

