% optickle should NOT be in the path, set the paths in optickleTestConfig

%% Clear classes
clear classes

%%
% run the test using the optFullIFO function that returns the opt object to
% test
addpath('testFunctions')
test = TickleTestOnOpt(@optFullIFO);
results = test.run();

disp(results)

global optickleTestResultsFile
load(optickleTestResultsFile);

%% run the Tickle01 tests

test = Tickle01TestOnOpt(@optFullIFO);
results = test.run();

disp(results)

global optickleTestResultsFile
data01 = load(optickleTestResultsFile);

%% extract the result data
% load the calculated data from disk, this makes variables with the names
% refStruct and calcStruct with the results of both calculations.

% plot the TF from ETMX to OMCDC

f = refStruct.f;

probe_OMCDC = 15;
probe_POPI1 = 17;
drive_EX = 12;

calcTF = squeeze(calcStruct.sigAC(probe_OMCDC,drive_EX,:));
refTF = squeeze(refStruct.sigAC(probe_OMCDC,drive_EX,:));

calcOMCNoise = calcStruct.noiseAC(probe_OMCDC,:);
refOMCNoise = refStruct.noiseAC(probe_OMCDC,:);

calcPOPNoise = calcStruct.noiseAC(probe_POPI1,:);
refPOPNoise = refStruct.noiseAC(probe_POPI1,:);

%% grab the 01 data
f = data01.refStruct.f;
probe01 = 5;
drive01 = 13;

calcTF01 = squeeze(data01.calcStruct.sigAC(probe01,drive01,:));
refTF01 = squeeze(data01.refStruct.sigAC(probe01,drive01,:));

%% plots
figure(333)
subplot(2,1,1)
loglog(f,abs(refTF),f,abs(calcTF),f,abs(refTF-calcTF));
title('EX pos to OMC DC');
legend('Reference (Optickle 1)','Calculated (Optickle 2)','Residual')
subplot(2,1,2)
semilogx(f,180/pi*angle(refTF),f,180/pi*angle(calcTF));

figure(334)
loglog(f,refOMCNoise,f,calcOMCNoise,f,abs(refOMCNoise-calcOMCNoise))
title('OMC DC Noise')
legend('Reference (Optickle 1)','Calculated (Optickle 2)','Residual')

figure(335)
loglog(f,refPOPNoise,f,calcPOPNoise,f,abs(refPOPNoise-calcPOPNoise))
title('POPI1 Noise')
legend('Reference (Optickle 1)','Calculated (Optickle 2)','Residual')

%% 01 plots

figure(455)
loglog(f,abs(refTF01),f,abs(calcTF01),f,abs(refTF01-calcTF01));
title('EX pos to OMC DC');
legend('Reference (Optickle 1)','Calculated (Optickle 2)','Residual')
subplot(2,1,2)
semilogx(f,180/pi*angle(refTF01),f,180/pi*angle(calcTF01));