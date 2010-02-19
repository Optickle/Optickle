% parWaitForLabs(taksCompletionObj)
%   wait for labs to complete a job (see parRunOnLabs)

% written by Matthew Evans, Feb 2010
%
% mostly borrowed from distcomp.pctRunOnAll

function parWaitForLabs(taksCompletionObj)
  
  % get the current session
  session = com.mathworks.toolbox.distcomp.pmode.SessionFactory.getCurrentSession;
  if isempty(session) || ~session.isSessionRunning
    error('parWaitForLabs:NotRunning', ...
      'Cannot execute parWaitForLabs when matlabpool is not running.');
  end

  % wait for this to finish
  while ~taksCompletionObj.waitForCompletion(1, ...
      java.util.concurrent.TimeUnit.SECONDS)
    if ~session.isSessionRunning
        error('parWaitForLabs:NotRunning', ...
            'The matlabpool on which the command was run has been shut down');
    end
  end
end
