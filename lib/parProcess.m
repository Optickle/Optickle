% stateInfo = parProcess(processFunc, consumeFunc, supplyFunc, ...
%                        stateInfo, processInfo, NthreadMax)
%   process data in parallel (see pforfun)
%
%   processFunc = function for processing data
%   consumeFunc = function for consuming processed data
%   supplyFunc = function for supplying data to process
%   stateInfo = struct or object available to the consume and supply functions
%               stateInfo can be changed by each call to these functions
%   processInfo = struct or object available to the process function
%                 processInfo can not be changed by the process function
%
% Parallel processing works by calling the supply function, passing the
% data supplied to the process function, and passing the processed result
% to the consume function.  This process is repeated while stateInfo.isReady
% is true.
%
% The supply function must take 1 input argument, stateInfo, and must return
% 2 output arguments; an updated stateInfo, and the data to process.
%   [stateInfo, data] = supplyFunc(stateInfo);
%
% The process function must take 2 input arguments, the processInfo and the
% data to process, and must return the processed data.
%   data = processFunc(processInfo, data);
%
% The consume function must take 3 input arguments, the stateInfo, the
% processed data, and the index indicating which call to supplyFunc produced
% the processed data.  It must return the updated stateInfo.
%   stateInfo = consumeFunc(stateInfo, data, n);
%
% Below are 3 serial code blocks equivalent to the call to parProcess shown
% above.  They demonstrate that the supply, process, and consume functions
% must be insensitive to the order in which they are called.
%
% ------------- Equivalent Code -------------
%
% n = 1;
% while stateInfo.isReady
%   [stateInfo, data] = supplyFunc(stateInfo);
%   data = processFunc(processInfo, data);
%   stateInfo = consumeFunc(stateInfo, data, n);
%   n = n + 1;
% end
%
% ------------- Equivalent Code -------------
%
% n = 1;
% while stateInfo.isReady
%   [stateInfo, data{n}] = supplyFunc(stateInfo);
%   n = n + 1;
% end
%
% Ndata = numel(data);
% for n = 1:Ndata
%   data{n} = processFunc(processInfo, data{n});
%   stateInfo = consumeFunc(stateInfo, data{n}, n);
% end
%
% ------------- Equivalent Code -------------
%
% n = 1;
% while stateInfo.isReady
%   [stateInfo, data{n}] = supplyFunc(stateInfo);
%   n = n + 1;
% end
%
% Ndata = numel(data);
% for n = Ndata:-1:1
%   data{n} = processFunc(processInfo, data{n});
%   stateInfo = consumeFunc(stateInfo, data{n}, n);
% end

% by Matthew Evans, Feb 2010
%
% much taken from parallel_function, PCT 2009a

function stateInfo = parProcess(processFunc, consumeFunc, supplyFunc, ...
                                stateInfo, processInfo, NthreadMax)

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Validate Arguments
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % Validate supplyFunc
  if ~isa(supplyFunc, 'function_handle')
    error('parProcess:InvalidArgument', ...
      'supplyFunc must be a function handle.');
  end
  
  % Validate processFunc
  if ~isa(processFunc, 'function_handle')
    error('parProcess:InvalidArgument', ...
      'processFunc must be a function handle.');
  end
  
  % Validate consumeFunc
  if ~isa(consumeFunc, 'function_handle')
    error('parProcess:InvalidArgument', ...
      'consumeFunc must be a function handle.');
  end
  
  % Validate stateInfo.isReady
  isReadyTest = stateInfo.isReady;
  if ~islogical(isReadyTest)
    error('parProcess:InvalidArgument', ...
      'stateInfo.isReady must yeild a logical.');
  end
  
  % Validate NthreadMax
  if ~(isnumeric(NthreadMax) && isscalar(NthreadMax) && ...
      NthreadMax == round(NthreadMax) &&  NthreadMax >= 0)
    error('parProcess:InvalidArgument', ...
      'The NthreadMax argument must be zero or a positive scalar integer.')
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Setup PARFOR Object
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % The number of workers.
  Nworkers = parGetNumLabs;
    
  % Parallel vs. Serial Decision
  if NthreadMax < 1 || Nworkers < 1
    % run the loop serially on the client
    parforObj = [];
  else
    try
      % get a remote parfor object
      parforObj = distcomp.remoteparfor(NthreadMax, @make_channel, ...
        processFunc, processInfo);
    catch E
      if strcmp( E.identifier, 'distcomp:remoteparfor:IllegalComposite' )
        % In this case, we wish to abort parfor execution
        E2 = MException('parProcess:InvalidComposite', ...
          'It is illegal to use a Composite processFunc');
        E2 = addCause( E2, E );
        throw( E2 );
      else
        % There are circumstances where we try to make a remoteparfor
        % controller and it throws an error (becuase it fails to acquire
        % the right resources for example). In that case we wish to fall
        % through to running locally
        warning('distcomp:remoteparfor:ParProcessRunningLocally', ...
          ['Error caught during construction of remote parfor code.\n' ...
          'The parfor construct will now be run locally rather than\n'...
          'on the remote matlabpool. The most likely cause of this is\n' ...
          'an inability to send over input arguments because of a\n'...
          'serialization error. The error report from the caught error is:\n%s'],...
          E.getReport);
        
        % run local
        parforObj = [];
      end
    end
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Execution
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % go local?
  if isempty(parforObj)
    n = 1;
    while stateInfo.isReady
      [stateInfo, data] = supplyFunc(stateInfo);
      data = processFunc(processInfo, data);
      stateInfo = consumeFunc(stateInfo, data, n);
      n = n + 1;
    end
    return
  end
  
  % distributed execution!
%   try
    stateInfo = distributed_execution(parforObj, ...
      consumeFunc, supplyFunc, stateInfo);
%   catch err
%     if strcmp(err.identifier, 'distcomp:parfor:SourceCodeNotAvailable')
%       % Get function on which we are operating
%       info = functions(processFunc);
%       newErr = MException('distcomp:parfor:SourceCodeNotAvailable', ...
%         ['The source code (%s) for the parfor loop that is trying to execute '...
%         'on the worker could not be found'], info.file);
%       newErr = addCause(newErr, err);
%       throw(newErr);
%     else
%       throw(err);
%     end
%   end
  
end

%----------------------------------------------------------------------------
% distributed_execution uses the PARFOR object to process data produced
% by the client-side supply function.  The data is then incorporated into
% stateInfo by the client-side consume function.
%----------------------------------------------------------------------------
function stateInfo = distributed_execution(parforObj, ...
    consumeFunc, supplyFunc, stateInfo)

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % enqueue and dequeue until supply runs dry
  
  Nworkers = parforObj.NumWorkers;  % actual number of workers obtained
  Nsupplied = 0;                    % the number of calls to supply function
  Nconsumed = 0;                    % the number of calls to consume function

  isOk = true;
  while isOk && stateInfo.isReady
    
    % if the number in the queue is more than twice the number of workers,
    %  try to get some out of the queue
    Nget = Nsupplied - Nconsumed - 2 * Nworkers;
    while Nget > 0
      % wait for workers to finish
      [n, data] = parforObj.getCompleteIntervals(Nget);
      
      % consume the processed data
      for nn = 1:numel(n)
        stateInfo = consumeFunc(stateInfo, data{nn}, n(nn));
        Nconsumed = Nconsumed + 1;
      end
      
      % get more?
      Nget = Nsupplied - Nconsumed - 2 * Nworkers;
    end
    
    % supply data for processing
    [stateInfo, data] = supplyFunc(stateInfo);
    Nsupplied = Nsupplied + 1;
   
    % add data to the queue of tasks
    isOk = parforObj.addInterval(Nsupplied, {data});
  end
  
  % wait for all workers to finish
  while Nconsumed < Nsupplied
    [n, data] = parforObj.getCompleteIntervals(Nsupplied - Nconsumed);
  
    % consume the processed data
    for nn = 1:numel(n)
      stateInfo = consumeFunc(stateInfo, data{nn}, n(nn));
      if n(nn) <= Nsupplied
        Nconsumed = Nconsumed + 1;
      end
    end
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % add the right number of final intervals (why? see PARALLEL_FUNCTION)
  for n = 1:Nworkers
    if ~parforObj.addFinalInterval(Nsupplied + n, {})
      break;
    end
  end
  
  % tell this PARFOR object that we are done
  parforObj.complete();

  %fprintf('dist_exec: Nsupplied = %d, Nconsumed = %d\n', Nsupplied, Nconsumed);
end

%----------------------------------------------------------------------------
% make_channel returns a "channel"
%   this "channel" is a pointer to a function which takes a single
%   cell array argument and calls the target function processFunc as
%     outputData = processFunc(processInfo, channelArg{:});
%----------------------------------------------------------------------------
function channel = make_channel(processFunc, processInfo)
  
  function outputData = channel_general(channelArg)
    if isempty(channelArg)
      % Exit condition denoted by an empty argument
      outputData = [];
    else
      % call processFunc
      feval('_workspace_transparency',1)
      outputData = processFunc(processInfo, channelArg{:});
    end
  end
  channel = @channel_general;
end
