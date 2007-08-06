Optickle is a general model for the electro-opto-mechanical
part of a GW detector.  It ventures into mechanics only as
far as is necessary to include radiation pressure effects,
and into electronics only far enough to produce demodulation
signals, and into optics only up to first order.  There are
many other tools that do all these things in greater detail.
Optickle is for quick, rough, but essentially complete design
studies.

In Optickle you can, in principal, simulate any interferometer.
The provided examples are a Fabry-Perot cavity, a LIGO like
IFO with DC readout (LIGOp), and an Advanced LIGO like signal
recycled IFO (LIGO2).  Each example has a few functions from
which the user might be able to learn.

To run the LIGOp example functions, go to the Optickle directory
and start matlab there, then:
>> addpath(pwd)
>> cd LIGOp/

Now you are ready to run the LIGOp examples.  There are several
sweep functions, which move a linear combination of mirrors to
produce signals at each point in the "sweep".
>> sweepPRCL(201);
>> sweepCARM(201);
>> sweepDARM(201);

And some functions for plotting the performance of DC readout.
>> offsetDARM;
>> f = logspace(0, 4, 200)';
>> respDARM(f, 1e-11, 1e-13)

The LIGO2 example is used in a similar way, with sweep functions
(DARM, CARM, PRCL and SRCL) and a simple DARM loop and noise
projections (respDARM).

======================================================
The anatomy of an Optickle model is probably best seen by looking
at the example functions optFP, optLIGOp and optLIGO2.  Some parts
of optFP.m (from the Examples directory) are show here.

One starts by creating an empty Optickle model.
  % create an empty Optickle model
  opt = Optickle;

The the various pieces (a.k.a. optics) are added to the model.
These include:
  1) a source, which is basically the laser
  2) modulators, which can have an modulation phase of 1 (AM) or i (PM)
     or anything in between.
  3) mirrors... a boring but important part of any IFO
  4) and sinks, which serve as anchors for later probing (and, in future
     versions, probably shot noise production)

  % add an AM modulator
  [opt, nAM] = addModulator(opt, 'AM', 1);

  % add mirrors
  [opt, nIX] = addMirror(opt, 'IX', 0, 1 / Ri, 0.03, 50e-6);
  [opt, nEX] = addMirror(opt, 'EX', 0, 1 / Re, 100e-6, 50e-6);

  % add detectors
  [opt, nREFL] = addSink(opt, 'REFL');
  [opt, nTRNS] = addSink(opt, 'TRNS');

The mechanical properties of mirrors, which are important for determing
their response to radiation pressure, can be set with setMechTF.

  % set some mechanical transfer functions
  opt = setMechTF(opt, nIX, zpk([], -wI * [0.1 + 1i, 0.1 - 1i], 1 / mI));
  opt = setMechTF(opt, nEX, zpk([], -wE * [0.1 + 1i, 0.1 - 1i], 1 / mE));

Once all the optics are in place, they can be attached together with
links.  These links represent the vacuumm through which light propagates
to go from one optic to the next.

  % add links
  opt = addLink(opt, nSrc, 'out', nAM, 'in', 0);
  opt = addLink(opt, nAM, 'out', nIX, 'bk', 10);
  opt = addLink(opt, nIX, 'fr', nEX, 'fr', lCav);
  opt = addLink(opt, nEX, 'fr', nIX, 'fr', lCav);
  opt = addLink(opt, nIX, 'bk', nREFL, 'in', 5);
  opt = addLink(opt, nEX, 'bk', nTRNS, 'in', 5);

Finally, probes produce signals.  Demodulated signals are made by
setting the demodulation frequency of the probe.  A demod frequency
of zero is a DC signal.  The output of every probe is a real number,
typically representing a voltage.  A transfer matrix will, of course,
have complex values despite this fact (see sigAC returned by compute).
Probes are typically placed at sinks, but they can be placed anywhere
and without disturbing beam propagation (ah, the beauty of simulation).

  % add probes
  opt = addProbeAt(opt, 'REFL_DC', nREFL, 'in', 0, 0);		% DC
  opt = addProbeAt(opt, 'REFL_AC', nREFL, 'in', fMod, 0);	% 1f demod
  opt = addProbeAt(opt, 'REFL_AC', nREFL, 'in', fMod, 90);	% 1f demod
  opt = addProbeAt(opt, 'TRNS_DC', nTRNS, 'in', 0, 0);		% DC

There is much more to say, but for now look at the examples, and
use the help command!  If things get bad, you can always send me
email.  I like questions from people who actually use my code.  At
least the first few questions.

-Matt

mevans@ligo.caltech.edu
mevans@ego-gw.it
