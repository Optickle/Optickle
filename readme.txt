Optickle is a general model for the electro-opto-mechanical
part of a GW detector.  It ventures into mechanics only as
far as is necessary to include radiation pressure effects,
and into electronics only far enough to produce demodulation
signals, and into optics only up to first order.  There are
many other tools that do all these things in greater detail.
Optickle is for quick, rough, but essentially complete design
studies.

In Optickle you can, in principal, simulate any interferometer.
The provided example is a Fabry-Perot cavity, optFP.  There are
currently two demo files which you are encouraged to run and read:
demoDetuneFP and demoLscFP.  Alignment sensing and control demos
lacking, so for now just read the help on tickle01.

>> cd Optickle
>> 
>> 
>> path(pathdef)
>> addpath(genpath(pwd))
>> 
>> demoLscFP
>> demoDetuneFP

There is much more to say, but for now look at the demos, and
use the help command!  If things get bad, you can always send me
email.  I like questions from people who actually use my code.  At
least the first few questions.

-Matt

mevans@ligo.mit.edu
mevans@ligo.caltech.edu
mevans@ego-gw.it
