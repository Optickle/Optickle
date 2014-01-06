% generic subsasgn for open access

function obj = subsasgn(obj, s, val)

  % deal with first operator
  ss = s(1);

  if( length(s) == 1 )
    switch ss.type
      case '()'
        obj(ss.subs{:}) = val;
      case '{}'
        obj{ss.subs{:}} = val;
      case '.'
        obj = set(obj, ss.subs, val);
      otherwise
        error('Dunno how to %s index an %s.', ss.type, class(obj));
    end
  else
    switch ss.type
      case '()'
        obj(ss.subs{:}) = subsasgn(obj(ss.subs{:}), s(2:end), val);
      case '{}'
        obj{ss.subs{:}} = subsasgn(obj{ss.subs{:}}, s(2:end), val);
      case '.'
        obj = set(obj, ss.subs, subsasgn(get(obj, ss.subs), s(2:end), val));
      otherwise
        error('Dunno how to %s index an %s.', ss.type, class(obj));
    end
  end
