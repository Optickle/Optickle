% optickle should NOT be in the path, set the paths in optickleTestConfig

%% Clear classes
clear classes

%%
% run the test using the optFullIFO function that returns the opt object to
% test
addpath('testModels')
addpath('testClasses')
test = TickleTestOnOpt(@optFullIFO);
results = test.run();

%% display results
disp(results)

numFailed = any(cell2mat({results.Failed}));

%% extract the result data
if numFailed > 0
    % load the calculated data from disk, this makes variables with the names
    % refStruct and calcStruct with the results of both calculations.
    
    global optickleTestResultsFile
    load(optickleTestResultsFile);
    
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
end