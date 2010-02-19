% parLab2Client(labVariable, labs, clientVariable)
%   get a variable from a lab to the client
%   (see pmode lab2client, parRunOnLabs, parClient2Lab)
%
% labVariable = name of the lab-side variable to get
% labs = lab to get the variable from (may be vector, or [] for all)
% clientVariable = name of the client-side variable (default is labVariable)
%   if multiple labs are specified, the client-side variable is a cell array
%
% NOTE: variables are sent and received in the base workspace
%       All labs must be idle for any to send variables.
%
% Example, get variable n from lab 1:
% parLab2Client('n', 1)

% written by Matthew Evans, Feb 2010
%
% mostly borrowed from distcomp.pmode

function parLab2Client(labVariable, labs, clientVariable)
  
  % check number of inputs
  if nargin < 1 || nargin > 3
    error('parLab2Client:InvalidInput', ...
      'parClient2Lab requires 1, 2 or 3 arguments.');
  end
  
  % default to all labs
  if nargin < 2
    labs = [];
  end
  
  % default destination variable name
  if nargin < 3
    clientVariable = labVariable;
  end
  
  % check variable names
  if ~isvarname(clientVariable)
    error('parLab2Client:InvalidInput', ...
      'Invalid name of source variable.');
  end
  if ~isvarname(labVariable)
    error('parLab2Client:InvalidInput', ...
      'Invalid name of target variable.');
  end
  
  % make sure we are on the client
  if system_dependent('isdmlworker')
    error('parLab2Client:InvalidInput', ...
      'parClient2Lab must be run on the client.');
  end
  
  % and that the matlabpool is running
  client = distcomp.getInteractiveObject();
  if ~client.isPossiblyRunning()
    error('parLab2Client:NotRunning', ...
      'Cannot execute parClient2Lab matlabpool is not running.');
  end
  
  % check labs argument
  numlabs = iGetNumLabs;
  if isempty(labs)
    labs = 1:numlabs;
  elseif ~iIsIntegerVector(labs, 1, numlabs)
    error('parLab2Client:InvalidInput', ...
      'The destination lab must be an integer between 1 and %d.', numlabs);
  end
  
  % finally, do it
  Nlab = numel(labs);
  if Nlab == 1
    client.lab2client(labVariable, labs, clientVariable);
  else
    baseVarTmp = 'PARLAB2CLIENT_TMP';
    assignin('base', clientVariable, cell(1, Nlab));
    for n = 1:Nlab
      client.lab2client(labVariable, labs(n), baseVarTmp);
      evalin('base', sprintf('%s{%d} = %s;', ...
        clientVariable, n, baseVarTmp));
    end
    evalin('base', ['clear ' baseVarTmp]);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check if input is a vector of integers within the specified bounds.
function valid = iIsIntegerVector(value, lowerBound, upperBound)
  valid = isnumeric(value) && isreal(value) && isvector(value) ...
    && all((value >= lowerBound)) && all(value <= upperBound) ...
    && all(isfinite(value)) && all(fix(value) == value);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get number of labs running
function nlabs = iGetNumLabs
  try
    session = com.mathworks.toolbox.distcomp.pmode.SessionFactory.getCurrentSession;
    labs = session.getLabs();
    nlabs = labs.getNumLabs();
  catch err
    newEx = MException('parLab2Client:NotRunning', ...
      'Cannot execute parClient2Lab when matlabpool is not running.');
    newEx = newEx.addCause(err);
    throw(newEx);
  end
end
