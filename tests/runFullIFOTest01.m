% optickle should NOT be in the path, set the paths in optickleTestConfig

%% Clear classes
clear classes
addpath('testModels')
addpath('testClasses')

%% run the Tickle01 tests

S = warning('OFF','OPTICKLE:FieldInconsistency');
test01 = Tickle01TestOnOpt(@optFullIFO);
results01 = test01.run();

warning(S);

%% display results
disp(results01)

%% grab the 01 data
    
global optickleTestResultsFile
data01 = load(optickleTestResultsFile);

f = data01.refStruct.f;
probe01 = 21;
drive01 = 13;

calcTF01 = squeeze(data01.calcStruct.sigAC(probe01,drive01,:));
refTF01 = squeeze(data01.refStruct.sigAC(probe01,drive01,:));


%% 01 plots

figure(455)
subplot(2,1,1)
loglog(f,abs(refTF01),f,abs(calcTF01),f,abs(refTF01-calcTF01));
title('EY pit to TRXDC');
legend('Reference (Optickle 1)','Calculated (Optickle 2)','Residual')
subplot(2,1,2)
semilogx(f,180/pi*angle(refTF01),f,180/pi*angle(calcTF01));