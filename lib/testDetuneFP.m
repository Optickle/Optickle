function exitCond = testDetuneFP()
    exitCond = 0;
    
    referenceStruct = load('testDetuneFP.mat');
    % referenceStruct is saved with commands:
    % output = demoDetuneFP(0);
    % save('testDetuneFP.mat','-struct','output')
    
    tic
    calculationStruct = demoDetuneFP(0);
    toc
    
    numericalEquality = isequaln(referenceStruct,calculationStruct);

    if ~numericalEquality
        warning('Answers are numerically different, this may be OK if error is small')
        exitCond = exitCond+1;
    end
    
    
    %%% test DC calculations
    exitCond = exitCond + checkForErrors('DC',{'fDC0','fDC1','fDC2','sigDC0','sigDC1','sigDC2'},...
                   calculationStruct,referenceStruct);
    
    
    %%% test TF calculations
    exitCond = exitCond + checkForErrors('Transfer function',{'sigAC0','sigAC1','sigAC2','mMech0','mMech1','mMech2'},...
                   calculationStruct,referenceStruct);
    
    %%% test Noise calculations
    exitCond = exitCond + checkForErrors('Noise',{'noiseAC0','noiseAC1','noiseAC2'},...
                   calculationStruct,referenceStruct);
end


function errorCount = checkForErrors(label, fieldNames, calcStruct, refStruct)
    errorCount = 0;
    errorThreshold = 1e-14;

    for name = fieldNames
        try
            calcMat = calcStruct.(name{:});
            refMat = refStruct.(name{:});
            
            errorMat = abs(1 - calcMat./refMat);
            
            error = max(errorMat(:));
            
            if error > errorThreshold
                warning([label ' error is above threshold'])
                errorCount = errorCount + 1;
            end
        catch err
            warning(['Error occurred while calculating ' label ' calculation error: ' err.message])
            errorCount = errorCount + 1;
        end
    end

end