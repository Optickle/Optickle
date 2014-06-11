function exitCond = testDetuneFP()
    exitCond = 0;
    tic
    
    referenceStruct = load('testDetuneFP.mat');
    % referenceStruct is saved with commands:
    % output = demoDetuneFP(0);
    % save('testDetuneFP.mat','-struct','output')
    
    calculationStruct = demoDetuneFP(0);
    
    numericalEquality = isequaln(referenceStruct,calculationStruct);

    if ~numericalEquality
        warning('Answers are numerically different, this may be OK if error is small')
        exitCond = exitCond+1;
    end
    toc
end