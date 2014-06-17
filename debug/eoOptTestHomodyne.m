% Create an Optickle test case with
% just a source, an LO pickoff, a squeezer, 
% and a "Homodyne" comprised of a beamsplitter and two sinks

function opt = eoOptTestHomodyne

  % create model
  opt = Optickle([0]); %Just one carrier w/ no RF sidebands
  
  % add a source
  opt = addSource(opt, 'Laser', 1, 0, 0);

  % add a mirror to pickoff LO
  opt = addMirror(opt,'PO', 45, 0, 0.5, 0, 0, 0, 1.45);
  opt = addLink(opt, 'Laser', 'out', 'PO', 'fr',0);
  
  % add a Squeezer
  opt = addSqueezer(opt, 'Sqz1', 1064e-9 , 0, 1, 0, 10, 15, 0);
  opt = addLink(opt, 'PO', 'bk', 'Sqz1', 'in', 0.25);

  % add Homodyne BS
  opt = addMirror(opt, 'HDBS', 45, 0, 0.5, 0, 0, 0, 1.45);
  opt = addLink(opt, 'PO', 'fr', 'HDBS', 'fr', 0.25);
  opt = addLink(opt, 'Sqz1', 'out', 'HDBS', 'bk', 0.5);
  
  % add 2 Sinks
  opt = addSink(opt,'HD1');
  opt = addSink(opt,'HD2');
  opt = addLink(opt, 'HDBS', 'fr', 'HD1', 'in', 0.1);
  opt = addLink(opt, 'HDBS', 'bk', 'HD2', 'in', 0.1);
  
  % add probes for Homodyne PDs
  opt = addProbeIn(opt, 'HD1_DC', 'HD1', 'in', 0, 0);
  opt = addProbeIn(opt, 'HD2_DC', 'HD2', 'in', 0, 0);
end
