% generic subsref for open access

function val = subsref(obj, s)

  % deal with first operator
  ss = s(1);
  switch ss.type 
    case '()'
      val = obj(ss.subs{:});
    case '{}'
      val = obj{ss.subs{:}};
    case '.'
      % for debugging use only
      ok_list = {'Noptic', 'Ndrive', 'Nlink', 'Nprobe', ...
                 'lambda', 'k', 'c', 'h', 'debug'};
      if obj.debug < 2 && isempty(strmatch(ss.subs, ok_list, 'exact'))
        warning('Direct reference to Optickle internals not allowed.');
      end
      
      val = get(obj, ss.subs);
    otherwise
      error('Dunno how to %s index an %s.', ss.type, class(obj));
  end

  % let result deal with later operators
  if( length(s) > 1 )
    val = subsref(val, s(2:end));
  end
