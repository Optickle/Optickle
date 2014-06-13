% Try to compare Optickle1 to Optickle2 using demoDetuneFP
close all
clear all
clear classes

%restoredefaultpath
path(pathdef)
addpath(genpath('~/tmp/Optickle2'))
outstruct = jmDemoDetuneFP;
save('temp.mat', 'outstruct')

close all
clear all
clear classes

%restoredefaultpath
path(pathdef)
addpath(genpath('~/tmp/Optickle'))
outstructOld = jmDemoDetuneFP;

load('temp.mat')
testDetuneFP(outstruct, outstructOld)

