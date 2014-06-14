classdef DetuneFPTest < OptickleTest
    % Define the constructor method
    methods
        function testCase = DetuneFPTest() 
            addpath('./testFunctions/')
            testCase.testFunctionHandle = @testDetuneFP;
        end
    end
    % Exact numerical equality is automatically tested, define additional
    % tests here
    methods (Test)
        function testDCCalculations(testCase)
            testCase.verifyCalcAndRefMatrices('DC',{'fDC0','fDC1','fDC2','sigDC0','sigDC1','sigDC2'});
        end
        function testTFCalculations(testCase)
            testCase.verifyCalcAndRefMatrices('Transfer function',{'sigAC0','sigAC1','sigAC2','mMech0','mMech1','mMech2'});
        end
        function testNoiseCalculations(testCase)
            testCase.verifyCalcAndRefMatrices('Noise',{'noiseAC0','noiseAC1','noiseAC2'});
        end
    end
end