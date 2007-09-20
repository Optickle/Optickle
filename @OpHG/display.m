% display

function display(op)

  if isempty(op)
    ans = []
  elseif numel(op) == 1
    x = op.x
    y = op.y
  else
    for n = 1:numel(op)
      n
      x = op(n).x
      y = op(n).y
    end
  end
  