% varargout = parallel_function(range, FUN, consume, supply, ...
%                               reduce, identity, concat, empty, ...
%                               M, divide, next_divide)
%
% This is an adaptation of PFORFUN (an interface to parProcess) which
% tries to intercept calls to PARALLEL_FUNCTION that originate with
% parfor loops.
%
% Unlike PARALLEL_FUNCTION, pforfun has adaptive load balancing and can
% display a wait bar to show progress of the processing.  The PFORFUN
% configInfo struct is copied from the global PARFOR_CONFIG.
%
%   PARFOR_CONFIG = configuration struct (optional)
%     .timePerExc = estimate of time required for each loop cycle (execution)
%     .batchTime = target batch execution time (default = 1 second)
%     .batchSize = number of executions per batch ([] for auto)
%     .minBatchSize = minimum number of executions per batch ([] for none)
%     .maxBatchSize = maximum number of executions per batch ([] for none)
%     .Nthread = maxiumum number of threads (workers) to use
%     .enableWaitBar = display a wait bar? {true, false}
%     .nameWaitBar = wait bar name
% (see pforfun for more info) 
%
% Example configuration:
%
% global PARFOR_CONFIG
%
% PARFOR_CONFIG.minBatchSize = 2;
% PARFOR_CONFIG.enableWaitBar = true;
% PARFOR_CONFIG.nameWaitBar = 'my parfor loop';
%
% ------------------ relavant help from PARALLEL_FUNCTION
%
%PARALLEL_FUNCTION runs a function in parallel and consumes/reduces the results.
%   PARALLEL_FUNCTION(RANGE, FUN) takes RANGE and a function handle FUN.  RANGE must
%   be a two-element row vector of integers which we'll call BASE and LIMIT.
%   These specify a semi-open interval (BASE,LIMIT].  If BASE >= LIMIT, nothing
%   happens because the interval is empty.  Otherwise, let N denote LIMIT-BASE,
%   i.e., the interval includes N integers.  PARALLEL_FUNCTION chooses k-1
%   intermediate points BASE < N_1 < ... < N_{k-1} < LIMIT, effectively dividing
%   the interval into k segments.  (Control over choosing k and the N_j will be
%   discussed below.)  We will use the convention that N_0 = BASE and
%   N_k = LIMIT.  Independently of k and the intermediate N_j, (0,N] is the
%   union of the subintervals (N_0,N_1],...,(N_{k-1},N_k].   PARALLEL_FUNCTION's
%   essence:
%
%     * In parallel, evaluate FUN(N_{j-1},N_j) in "worker" processes, j = 1,...,k.
%
%   The process on which PARALLEL_FUNCTION is called the "client".
%
%   Because the choice of intermediate points is non-deterministic,
%   PARALLEL_FUNCTION will be non-deterministic unless FUN obeys the rule that the
%   following statement sequences are equivalent:
%
%     * FUN(N_{j-1}, N_j) % process a subinterval
%       FUN(N_j, N_{j+1}) % process the next subinterval
%
%     * FUN(N_{j-1}, N_{j+1}) % process the combined subintervals
%
%   Because the order of processing is non-deterministic, PARALLEL_FUNCTION will
%   be non-deterministic unless FUN obeys the rule that for any j1 and j2, these
%   are equivalent:
%
%     * FUN(N_{j1-1}, N_j1); FUN(N_{j2-1}, N_j2); % process j1 first
%
%     * FUN(N_{j2-1}, N_j2); FUN(N_{j1-1}, N_j1); % process j2 first
%
%   Actually, the requirement is stronger than this: the two statements here
%   must not interfere with one another's execution.  For example, if they are
%   both competing to write the same file, there will be trouble.  We will call
%   this the "non-interference" rule.
%
%   Not only N_{j-1} and N_j are sent from the client to the workers, but so is
%   the function handle FUN.  Handles to nested functions are particularly useful
%   as values of FUN, because the values in their workspace are sent along with FUN.
%   This is the standard way to communicate loop-invariant values to workers.
%
%   Note: PARALLEL_FUNCTION is the basis for PARFOR execution, and if PARFOR is
%   sufficient for your purposes, it is a more convenient interface to this
%   functionality.  PARFOR uses the nested function technique to transmit its
%   unsliced input variables.
%
%
%   PARALLEL_FUNCTION(RANGE, FUN, CONSUME) provides a way for workers to send
%   values back to the client.  If CONSUME is [], the behavior is as above, i.e,
%   FUN is evaluated with no expected results.  Otherwise, CONSUME must be a
%   function handle, and FUN must return a result.  Each worker does this:
%
%     * Evaluates O = FUN(N_{j-1}, N_j).
%
%     * Sends O to the client.
%
%   As each O is received, the client calls CONSUME(N_{j-1},N_j, O).
%
%   Because the choice of intermediate points is non-deterministic,
%   PARALLEL_FUNCTION will be non-deterministic unless FUN and consume obey the
%   rule that the following statement sequences are equivalent:
%
%     * O1 = FUN(N_{j-1}, N_j);      % process a subinterval
%       O2 = FUN(N_j, N_{j+1});      % process the next subinterval
%       CONSUME(N_{j-1}, N_j, O1)  % consume the first output
%       CONSUME(N_j, N_{j+1}, O2)  % consume the second output
%
%     * O = FUN(N_{j-1}, N_{j+1});     % process the combined subintervals
%       CONSUME(N_{j-1}, N_{j+1}, O) % consume the entire output
%
%   Because the order of processing is non-deterministic, PARALLEL_FUNCTION will
%   be non-deterministic unless FUN obeys the non-interference rule, extended for
%   outputs: for any distinct j1 and j2, the following may be executed
%   concurrently:
%
%     * O1 = FUN(N_{j1-1}, N_j1);
%
%     * O2 = FUN(N_{j2-1}, N_j2)
%
%   Calls on CONSUME occur in the client, and thus are serially executed.  Since
%   the order in which this happens is not guaranteed, PARALLEL_FUNCTION will be
%   non-deterministic unless CONSUME obeys the rule that for any j1 and j2, where
%   O1 and O2 arise as above, these are equivalent:
%
%     * CONSUME(N_{j1-1},N_j1, O1); CONSUME(N_{j2-1},N_j2, O2)
%
%     * CONSUME(N_{j2-1},N_j2, O2); CONSUME(N_{j1-1},N_j1, O1)
%
%   We say that CONSUME is "order-insensitive".
%
%   The final constraint comes from the observation that CONSUME runs on the
%   client and FUN on a worker, so there is an other form of the non-interference
%   requirement: for any distinct j1 and j2, the following may be executed
%   concurrently:
%
%     * O1 = FUN(N_{j1-1}, N_j1);
%
%     * CONSUME(N_{j2-1},N_j2, O2)
%
%   Note:  Even more so in this case, PARFOR is a convenient interface to this
%   functionality.  It uses CONSUME to implement its output sliced variables.
%
%
%   PARALLEL_FUNCTION(RANGE, FUN, CONSUME, SUPPLY) provides a way for the client
%   to send a worker a piece of data relevant only to its subinterval.  If
%   SUPPLY is [], the behavior is as above.  Otherwise, SUPPLY must be a
%   function handle (in practice, almost invariably to a nested function).
%   The client does the following:
%
%     * Evaluates I = SUPPLY(N_{j-1},N_j)
%
%     * Sends I to the worker along with N_{j-1} and N_j.
%
%   A worker evaluates FUN(N_{j-1}, N_j, I), with a result requested or not,
%   depending upon whether CONSUME is a function handle (as above).
%
%   Note: PARFOR uses SUPPLY for its sliced input variables.
%
% see lang/parallel_function for more info

% original version (Matlab 2009a, PCT)
%   Copyright 1984-2007 The MathWorks, Inc.
%   $Revision $ $Date: 2010/04/15 16:25:20 $
%
% modified by Matthew Evans, Feb 2010
%   adaptation of pforfun

function varargout = parallel_function(varargin)

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Select Desired Cases
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % if this isn't the simple case we are looking for,
  % call the real thing
  if nargin < 4 || nargin > 8 || nargout > 0 || ...   % wrong number of args
      (nargin >= 5 && ~isempty(varargin{5})) || ...   % has reducer
      (nargin >= 7 && ~isempty(varargin{7}))          % has concat
  
    % call the real one
    pfLang = getRealParallelFunction;
    varargout = pfLang(varargin{:});
    return;
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Validate Arguments
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % fill missing args with empty matrix
  if nargin < 9
    varargin{9} = Inf;
  end

  % extract a few args (ignore the others)
  range = varargin{1};
  FUN = varargin{2};
  consume = varargin{3};
  supply = varargin{4};
  NthreadMax = varargin{9};
  
  % Validate range
  if ~isequal(size(range), [1 2]) || ~isnumeric(range)
    error('MATLAB:parfor:InvalidArgument', 'RANGE must be a row vector with length 2, of numerics.')
  end
  base = range(1) - 1;   % WRONG: this is not how range is defined in the header
  limit = range(2);
  Nexc = limit - base;
  
  % Validate base and limit
  if ~isreal(base) || ~isreal(limit)
    error('MATLAB:parfor:InvalidArgument', 'BASE and LIMIT arguments must be real.')
  end
  if base ~= round(base) || limit ~= round(limit)
    error('MATLAB:parfor:InvalidArgument', 'BASE and LIMIT arguments must be integers.')
  end

  % Validate FUN
  if ~isa(FUN, 'function_handle')
    error('MATLAB:parfor:InvalidArgument', 'FUN must be a function handle.');
  end
  
  % Validate consume
  if ~isempty(consume) && ~isa(consume, 'function_handle')
    error('MATLAB:parfor:InvalidArgument', ...
      'CONSUME must be a function handle or [].');
  end
  
  % Validate supply
  if ~isempty(supply) && ~isa(supply, 'function_handle')
    error('MATLAB:parfor:InvalidArgument', ...
      'SUPPLY must be a function handle or [].');
  end
  
  % Validate NthreadMax
  if isnumeric(NthreadMax) && isscalar(NthreadMax) && ...
      NthreadMax == round(NthreadMax) &&  NthreadMax >= 0
    NthreadMax = double(NthreadMax);
  else
    error('MATLAB:parfor:InvalidArgument', ...
      'The M argument must be zero or a positive scalar integer.')
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Validate Config
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  global PARFOR_CONFIG
  
  % config info
  if isempty(PARFOR_CONFIG) || ~isstruct(PARFOR_CONFIG)
    configInfo = struct;
  else
    configInfo = PARFOR_CONFIG;
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
      ~iIsIntegerScalar(configInfo.batchSize, 1, Nexc)
      error('batchSize must be an integer scalar > 0 and < %d.', Nexc)
  end
  
  if ~isfield(configInfo, 'minBatchSize')
    configInfo.minBatchSize = 1;    % set minimum to 1
  elseif ~isempty(configInfo.minBatchSize) && ...
      ~iIsIntegerScalar(configInfo.minBatchSize, 1, Inf)
      error('minBatchSize must be an integer scalar > 0.')
  end
  
  if ~isfield(configInfo, 'maxBatchSize')
    configInfo.maxBatchSize = [];    % decide later
  elseif ~isempty(configInfo.maxBatchSize) && ...
      ~iIsIntegerScalar(configInfo.maxBatchSize, 1, Inf)
      error('maxBatchSize must be an integer scalar > 0.')
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
  stateInfo.supply = supply;
  stateInfo.consume = consume;
  
  stateInfo.isReady = Nexc > 0;
  stateInfo.base = base;
  stateInfo.limit = limit;
  stateInfo.interval = [];

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Call parProcess
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % processing function
  processInfo.fun = FUN;
  
  % call parallel_function
  stateInfo = parProcess(@iParFun, @iConsume, @iSupply, ...
    stateInfo, processInfo, NthreadMax);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Clean up
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
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
function output = iParFun(processInfo, input)
  % measure the cpu time required
  tStart = cputime;
  
  % this is run worker-side... just pass on through
  output.base = input.base;
  output.limit = input.limit;
  switch input.type
    case 0
      % supply and consume
      output.data = processInfo.fun(input.base, input.limit, input.data);
    case 1
      % consume only
      output.data = processInfo.fun(input.base, input.limit);
    case 2
      % supply only
      processInfo.fun(input.base, input.limit, input.data);
    case 3
      % no supply and no consume
      processInfo.fun(input.base, input.limit);
  end
  
  % include execution time in output
  output.tExc = cputime - tStart;
  
  %fprintf('iParFun(%d data) took %.2fs\n', numel(output.data), output.tExc)  
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% iConsume
%   the data consumption function for parProcess
function stateInfo = iConsume(stateInfo, output, n)
  
  % check for clean-up interval
  if isempty(output)
    if ~isempty(stateInfo.consume)
      stateInfo.consume([], [], []);
    end
    return
  end
  
  % extract base and limit for this interval
  base = output.base;
  limit = output.limit;
  
  % consume the output
  if ~isempty(stateInfo.consume)
    stateInfo.consume(base, limit, output.data);
  end
  
  % save the interval execution time
  if n <= size(stateInfo.interval, 1)
    stateInfo.interval(n, 3) = output.tExc;
  end
  
  
  % update waitbar
  if stateInfo.config.enableWaitBar
    stateInfo.wait = iUpdateWait(stateInfo.wait, limit - base);
  end
  
  %fprintf('iConsume((%d, %d), (%d %s), %d)\n', base, limit, ...
  %  numel(output.data), class(output.data), n)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% iSupply
%   the data supply function for parProcess
function [stateInfo, input] = iSupply(stateInfo)

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
  input.type = isempty(stateInfo.supply) + 2 * isempty(stateInfo.consume);
  input.base = base;
  input.limit = limit;
  if ~isempty(stateInfo.supply)
    input.data = stateInfo.supply(base, limit);
  end
  
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% return a pointer to the real parallel_function
function pfLang = getRealParallelFunction
  
  % this is a function pointer to the real thing
  persistent LANG_PARALLEL_FUNCTION
  
  % find real parallel_function
  if isempty(LANG_PARALLEL_FUNCTION)
      
    % set path to default
    currentPath = path;
    currentPWD = pwd;
    path(pathdef);
    
    % save a pointer to the real parallel_function
    fileList = which('parallel_function', '-all');
    if isempty(fileList)
      error('Unable to find the real parallel_function.  Damn.')
    else
      warning('Reverting to the real parallel_function for this.  Sorry.')
    end
    
    cd(fileparts(fileList{end}));
    LANG_PARALLEL_FUNCTION = @parallel_function;
    
    % reset the path and working directory
    path(currentPath)
    cd(currentPWD);
  end
  
  pfLang = LANG_PARALLEL_FUNCTION;
end
