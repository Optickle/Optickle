% xy = figsize(xy)
% [x, y] = figsize(x, y)
%   change the size of a figure
%
% first argument can be [x, y], or just x
% second argument is y
% return value is matches number of output arugments

function varargout = figsize(x, y)

  % set position
  if nargin > 0
    pf = get(gcf, 'Position');
    if nargin == 1
      y = x(2);
      x = x(1);
    end
    set(gcf, 'Position', [pf(1:2), x, y]);
  end

  % return position
  pf = get(gcf, 'Position');
  x = pf(3:4);
  
  switch nargout
    case 0
      if nargin > 0
        varargout = {};
      else
        varargout = {x};
      end      
    case 1
      varargout = {x};
    case 2
      varargout = {x(1) x(2)};
    otherwise
      error('Too many output arguments.') 
  end
end  