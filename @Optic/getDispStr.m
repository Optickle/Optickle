% for use by derived classes for standard display

function str = getDispStr(obj, typeStr)

  % make input string
  if isempty(find(obj.in, 1))
    inStr = 'in: none';
  else
    inStr = 'in:';
    
    for m = 1:obj.Nin
      if obj.in(m)
        inStr = [inStr, sprintf(' %s=%d', obj.inNames{m}{1}, ...
          obj.in(m))];
      end
    end
  end
  
  % make output string
  if isempty(find(obj.out, 1))
    outStr = 'out: none';
  else
    outStr = 'out:';
    for m = 1:obj.Nout
      if obj.out(m)
        outStr = [outStr, sprintf(' %s=%d', obj.outNames{m}{1}, ...
          obj.out(m))];
      end
    end
  end

  % make complete string
  str = sprintf('%d)  %s is a %s (%s, %s)', ...
    obj.sn, obj.name, typeStr, inStr, outStr);
