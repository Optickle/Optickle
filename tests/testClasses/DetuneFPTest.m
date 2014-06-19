classdef DetuneFPTest < OptickleTest
    % Define the constructor method
    methods
        function testCase = DetuneFPTest() 
            addpath('./testModels/')
            testCase.testFunctionHandle = @testDetuneFP;
        end
    end
    % Exact numerical equality is automatically tested, define additional
    % tests here
    methods (Test)
        function testDCFields(testCase)
            testCase.verifyCalcAndRefMatrices('DC fields',{'fDC0','fDC1','fDC2'});
        end
        function testDCSignals(testCase)
            testCase.verifyCalcAndRefMatrices('DC signals',{'sigDC0','sigDC1','sigDC2'});
        end
        function testTFs(testCase)
            testCase.verifyCalcAndRefMatrices('Transfer function',{'sigAC0','sigAC1','sigAC2','mMech0','mMech1','mMech2'});
        end
        function testNoises(testCase)
            testCase.verifyCalcAndRefMatrices('Noise',{'noiseAC0','noiseAC1','noiseAC2'});
        end
        function test01TFs(testCase)
            testCase.verifyCalcAndRefMatrices('01 Transfer function',{'sigAC01','mMech01'});
        end
    end
end