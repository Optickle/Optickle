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
    val = get(obj, ss.subs);
   otherwise
    error('Dunno how to %s index an %s.', ss.type, class(obj));
  end

  % let result deal with later operators
  if( length(s) > 1 )
    val = subsref(val, s(2:end));
  end
