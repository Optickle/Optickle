classdef Tickle01TestOnOpt < OptickleReferenceTest
    properties 
        optFuncHandle
    end
    
    methods
        % Define the constructor method
        function testCase = Tickle01TestOnOpt(optFuncHandle) 
            testCase.optFuncHandle = optFuncHandle;
            
            testCase.testFunctionHandle = @()computeResults(testCase);
            testCase.testLabel = [ class(testCase) '(@' func2str(testCase.optFuncHandle) ')'];
        end
        function resultStruct = computeResults(testCase)
            f = logspace(-1, 3, 200)';
            
            [sigAC, mMech] = tickle01(testCase.optFuncHandle(),[], f);
            
            resultStruct = var2struct(f,sigAC,mMech);
        end
    end
    % Exact numerical equality is automatically tested, define additional
    % tests here
    methods (Test)
        function testsigAC(testCase)
            testCase.verifyCalcAndRefMatrices('sigAC',{'sigAC'});
        end
        function testmMech(testCase)
            testCase.verifyCalcAndRefMatrices('mMech',{'mMech'});
        end
    end
end
