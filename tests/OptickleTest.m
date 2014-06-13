classdef OptickleTest < matlab.unittest.TestCase
    
    properties
        testFunctionHandle;
        referenceStruct;
        calculatedStruct;
        optickleLocation = which('Optickle');
    end
    properties
        config = optickleTestConfig();
    end
    
    % methods
    methods (Test)
        function testNumericalEquality(testCase)
            testCase.verifyEqual(testCase.referenceStruct,testCase.calculatedStruct);
        end
    end
    methods (TestClassSetup)
        function loadReferenceStruct(testCase)
            
            disp('---===Optickle Test===---')
            disp(['Reference type is ' testCase.config.referenceType])
            disp(['Reference path is ' testCase.config.referencePath])
            disp(['Optickle path is ' testCase.optickleLocation])
            
            switch testCase.config.referenceType
                case 'Path'
                    % remember path
                    origPath = path;
                    % add reference Optickle to path
                    addpath(testCase.config.referencePath);
                    addpath([testCase.config.referencePath '/lib'])
                    % call function
                    refStruct = testCase.testFunctionHandle();
                    % clear Optickle class
                    clearClassesButSave(refStruct,origPath);
                    % reset path
                    path(origPath);
                    % this is required because we have lost the original
                    % testCase variable.
                    global globalRefStruct; %#ok<TLEV>
                    globalRefStruct = refStruct;
                    return
                case 'Files'
                    % load struct from file
                    refPath = testCase.config.referencePath;
                    refStruct = load([refPath '/' func2str(testCase.testFunctionHandle) '.mat']);
                otherwise
                    error(['Sorry, I don''t understand referenceType: ',testCase.config.referenceType])
            end
            testCase.referenceStruct = refStruct;
        end
        function recoverGlobalReferenceStruct(testCase)
            global globalRefStruct
            if strcmp(testCase.config.referenceType,'Path')
                testCase.referenceStruct = globalRefStruct;
                clear GLOBALRefStruct
            end
        end
        function computeCalculatedStruct(testCase)
            testCase.calculatedStruct = testCase.testFunctionHandle();
        end
    end
    methods
        function saveTestFunctionOutputToReference(testCase)
            % TODO make this function
            
            if ~strcmp(testCase.config.referenceType,'Files')
                error('cannot save unless config.referenceType is Files')
            end
            
            testPath = testCase.config.referencePath;
            fileNameBase = [testPath '/' func2str(testCase.testFunctionHandle)];
            
            output = testCase.testFunctionHandle(); %#ok<NASGU>
            
            % write metadata
            textFileID = fopen([fileNameBase '.txt'],'w');
            fprintf(textFileID,'Optickle test reference data\n');
            fprintf(textFileID,'----------------------------\n');
            fprintf(textFileID,['Test function: ' func2str(testCase.testFunctionHandle) '\n']);
            fprintf(textFileID,['Path to Optickle: ' testCase.optickleLocation '\n']);
            fprintf(textFileID,['Run on: ' datestr(now) '\n']);
            fclose(textFileID);
            
            save([fileNameBase '.mat'],'-struct','output')
        end
        function verifyCalcAndRefMatrices(testCase,label, fieldNames)
            funHandle = @() testCase.warnOnMatrixFieldsInequalityInStruct(...
                label, fieldNames);
            
            testCase.verifyWarningFree(funHandle);
        end
        function warnOnMatrixFieldsInequalityInStruct(testCase,label, fieldNames)
            % precision is the product of these two numbers
            errorThreshold = 1e-6;
            smallNumber = 1e-12;
            
            % helper function
            function stringOut = cell2CommaSeparatedString(cellIn)
                stringOut = '';
                for jj = 1:length(cellIn)
                    stringOut = [stringOut num2str(cellIn{jj}) ', ']; %#ok<AGROW>
                end
                stringOut = stringOut(1:end-2);
            end
            
            for name = fieldNames
                calcMat = testCase.calculatedStruct.(name{:});
                refMat = testCase.referenceStruct.(name{:});
                
                small = max(abs(calcMat(:)))*smallNumber;
                
                errorMat = abs(calcMat-refMat)./(abs(calcMat)+abs(refMat)+small);
                
                error = max(errorMat(:));
                
                if error > errorThreshold
                    dim = length(size(errorMat));
                    
                    % find the index of the error
                    [ind{1:dim}] = ind2sub(size(errorMat),find(errorMat == max(errorMat(:)),1));
                    warning([label ' error is ' num2str(error) ' at index ['...
                        cell2CommaSeparatedString(ind) '] in variable ' name{:}])
                end
            end
        end
    end % methods
end