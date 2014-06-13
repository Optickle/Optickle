% Try to compare Optickle1 to Optickle2 using demoDetuneFP
close all
clear all
clear classes

restoredefaultpath
addpath(genpath('~/Documents/mit/Optickle'))
outstruct = jmDemoDetuneFP;
save('temp.mat', 'outstruct')

close all
clear all
clear classes

restoredefaultpath
addpath(genpath('~/Documents/mit/Optickle1'))
outstructOld = jmDemoDetuneFP;

load('temp.mat')
testDetuneFP(outstruct, outstructOld)

%close all
clear all
clear classes
