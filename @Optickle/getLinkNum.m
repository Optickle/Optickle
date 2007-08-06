% returns the serial number of a link, given the name of its source and sink.
%
% n = getLinkNum(opt, nameSource, nameSink)
% nameSource - name or serial number of source optic (link start)
% nameSink - name or serial number of sink optic (link end)
% n - array of link serial numbers

function n = getLinkNum(opt, nameSource, nameSink)

  snSource = getSerialNum(opt, nameSource);
  snSink = getSerialNum(opt, nameSink);

  n = [];
  for m = 1:opt.Nlink
    if opt.link(m).snSource == snSource && opt.link(m).snSink == snSink
      n = [n; m];
    end
  end
