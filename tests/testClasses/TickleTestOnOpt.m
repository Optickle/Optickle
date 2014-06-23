classdef TickleTestOnOpt < OptickleReferenceTest
    properties 
        optFuncHandle
    end
    
    methods
        % Define the constructor method
        function testCase = TickleTestOnOpt(optFuncHandle) 
            testCase.optFuncHandle = optFuncHandle;
            
            testCase.testFunctionHandle = @()computeResults(testCase);
        end
        function resultStruct = computeResults(testCase)
            f = logspace(-1, 3, 200)';
            
            [fDC, sigDC, sigAC, mMech, noiseAC] = tickle(testCase.optFuncHandle(),[], f);
            
            resultStruct = var2struct(f,fDC,sigDC,sigAC,mMech,noiseAC);
        end
    end
    % Exact numerical equality is automatically tested, define additional
    % tests here
    methods (Test)
        function testfDC(testCase)
            testCase.verifyCalcAndRefMatrices('fDC',{'fDC'});
        end
        function testsigDC(testCase)
            testCase.verifyCalcAndRefMatrices('sigDC',{'sigDC'});
        end
        function testsigAC(testCase)
            testCase.verifyCalcAndRefMatrices('sigAC',{'sigAC'});
        end
        function testmMech(testCase)
            testCase.verifyCalcAndRefMatrices('mMech',{'mMech'});
        end
        function testnoiseAC(testCase)
            testCase.verifyCalcAndRefMatrices('noiseAC',{'noiseAC'});
        end
    end
end
