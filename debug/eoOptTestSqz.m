% Create an Optickle test case with
% just a source, a squeezer, and a sink

function opt = eoOptTestSqz

  % create model
  opt = Optickle([0]); %Just one carrier w/ no RF sidebands
  
  % add a source
  opt = addSource(opt, 'Laser', 1, 0, 0);

  % add a Squeezer
  opt = addSqueezer(opt, 'Sqz1', 1064e-9 , 0, 1, 0, 10, 15, 0);
  opt = addLink(opt, 'Laser', 'out', 'Sqz1', 'in', 0);

  % add a Sink
  opt = addSink(opt,'SqzSink');
  opt = addLink(opt, 'Sqz1', 'out', 'SqzSink', 'in', 0);
  
  % add probe for squeezer sink
  opt = addProbeIn(opt, 'Sqz_DC', 'SqzSink', 'in', 0, 0);
end
