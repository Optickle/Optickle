% Hermite-Guass Opterator
%
% This operator can be applied to a HG basis vector
% (see the apply function).
%
% The default and copy constructors are available.
% op = OpHG;
% op = OpHG(op_old);
%
% The operators matrices can also be specified:
% op = OpHG(mxy);
% op = OpHG(mx, my);


function op = OpHG(varargin)

  op.x = eye(2);
  op.y = eye(2);

  op = class(op, 'OpHG');

  errstr = 'Don''t know what to do with ';	% for argument error messages
  switch( nargin )
   case 0					% default constructor
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%% 1 argument
   case 1
    arg = varargin{1};
    if( isa(arg, 'OpHG') )			% copy constructor
      op = arg;
    elseif isnan(arg)
      op.x = NaN;
      op.y = NaN;
    elseif all(size(arg) == [2, 2]) && isa(arg, 'double')
      op.x = arg;				% basis specified
      op.y = arg;				%   with op.x == op.y
    else
      error([errstr 'a %s.'], class(arg));
    end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%% 2 arguments
   case 2
    arg1 = varargin{1};
    arg2 = varargin{2};
    if all(size(arg1) == [2, 2]) && isa(arg1, 'double') && ...
          all(size(arg2) == [2, 2]) && isa(arg2, 'double')
      op.x = arg1;				% basis specified
      op.y = arg2;
    else
      error([errstr 'a %s and a %s.'], class(arg1), class(arg2));
    end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%% otherwise, error   
   otherwise					% wrong number of input args
    error([errstr '%d input arguments.'], nargin);
  end

end
