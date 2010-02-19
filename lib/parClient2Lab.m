% parClient2Lab(clientVariable, labs, labVariable)
%   send a variable from the client to some or all labs
%   (see pmode client2lab, parRunOnLabs, parLab2Client)
%
% clientVariable = name of the client-side variable to send
% labs = labs to send to (e.g., 1 or 1:3 or [] for all, default is [])
% labVariable = name of the lab-side variable (default is clientVariable)
%
% NOTE: variables are sent and received in the base workspace
%       All labs must be idle for any to receive variables.
%
% Example, send variable n to all labs:
% n = 1:10;
% parClient2Lab('n')

% written by Matthew Evans, Feb 2010
%
% mostly borrowed from distcomp.pmode

function parClient2Lab(clientVariable, labs, labVariable)
  
  % check number of inputs
  if nargin < 1 || nargin > 3
    error('parClient2Lab:InvalidInput', ...
      'parClient2Lab requires 1, 2 or 3 arguments.');
  end
  
  % default to all labs
  if nargin < 2
    labs = [];
  end
  
  % default destination variable name
  if nargin < 3
    labVariable = clientVariable;
  end
  
  % check variable names
  if ~isvarname(clientVariable)
    error('parClient2Lab:InvalidInput', ...
      'Invalid name of source variable.');
  end
  if ~isvarname(labVariable)
    error('parClient2Lab:InvalidInput', ...
      'Invalid name of target variable.');
  end
  
  % make sure we are on the client
  if system_dependent('isdmlworker')
    error('parClient2Lab:InvalidInput', ...
      'parClient2Lab must be run on the client.');
  end
  
  % and that the matlabpool is running
  client = distcomp.getInteractiveObject();
  if ~client.isPossiblyRunning()
    error('parClient2Lab:NotRunning', ...
      'Cannot execute parClient2Lab matlabpool is not running.');
  end
  
  % check labs argument
  numlabs = iGetNumLabs;
  if isempty(labs)
    labs = 1:numlabs;
  elseif ~iIsIntegerVector(labs, 1, numlabs)
    error('parClient2Lab:InvalidInput', ...
      'The destination lab(s) must be integer(s) between 1 and %d.', numlabs);
  end
  
  % finally, do it
  client.client2lab(clientVariable, labs, labVariable);
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
    newEx = MException('parClient2Lab:NotRunning', ...
      'Cannot execute parClient2Lab when matlabpool is not running.');
    newEx = newEx.addCause(err);
    throw(newEx);
  end
end
