% taksCompletionObj = parRunOnLabs(command, isBlocking)
%   run a command on all members of a matlabpool
%
%   parRunOnLabs allows a user to specify commands that should be run on
%   all matlabs in a matlabpool.  Unlike pctRunOnAll, the specified command
%   does not run on the client, and parRunOnLabs can be made non-blocking.
%
%   When running in the non-blocking mode (the default), the client can
%   wait for the labs to finish running the specified command by calling
%     parWaitForLabs(taksCompletionObj)
%
% Example:
%
% % send a value to all labs
% numRand = 4e3;
% parClient2Lab('numRand')
%
% % evaluate some expression in all labs
% tco = parRunOnLabs('resultRand = randn(numRand, 1);');
%
% % do other things...
%
% % wait for all labs to finish
% parWaitForLabs(tco)
%
% % get results back from the labs
% parLab2Client('resultRand')

% written by Matthew Evans, Feb 2010
%
% mostly borrowed from distcomp.pctRunOnAll

function varargout = parRunOnLabs(command, isBlocking)

  % get the current session
  session = com.mathworks.toolbox.distcomp.pmode.SessionFactory.getCurrentSession;
  if isempty(session) || ~session.isSessionRunning
    error('parRunOnLabs:NotRunning', ...
        ['Cannot execute parRunOnLabs %s \n', ...
        'when matlabpool is not running.'], command);
  end
  
  % get the labs
  labs = session.getLabs();
  if isempty(labs)
    error( 'parRunOnLabs:RunOnClient', ...
           'parRunOnLabs must be run either from the client');
  end
  
  % get task completion object
  taksCompletionObj = ...
    com.mathworks.toolbox.distcomp.pmode.RunOnAllCompletionObserver(labs.getNumLabs);
  
  % evaluate the command in all labs
  labs.eval(command, taksCompletionObj);

  % wait, or return
  if nargin > 1 && isBlocking
    parWaitForLabs(taksCompletionObj);
    varargout = {};
  else
    varargout{1} = taksCompletionObj;
  end
  
end
