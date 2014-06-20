classdef OptickleReferenceTest < matlab.unittest.TestCase
    
    properties
        testFunctionHandle;
        referenceStruct;
        calculatedStruct;
    end
    properties
        config = optickleTestConfig();
    end
    
    % methods
    methods (Test)
        function testNumericalEquality(testCase)
            testCase.verifyEqual(testCase.calculatedStruct,testCase.referenceStruct);
        end
    end
    methods (TestClassSetup)
        function displayConfig(testCase)
            disp('---===Optickle Test===---')
            disp(['Reference type is ' testCase.config.referenceType])
            disp(['Reference path is ' testCase.config.referencePath])
            disp(['Optickle path is ' testCase.config.calculationPath])
        end
        function loadReferenceStruct(testCase)
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
                clear globalRefStruct
            end
        end
        function computeCalculatedStruct(testCase)
            % remember path
            origPath = path;
            % add reference Optickle to path
            addpath(testCase.config.calculationPath);
            addpath([testCase.config.calculationPath '/lib'])
            % call function
            testCase.calculatedStruct = testCase.testFunctionHandle();
            % reset path
            path(origPath);
        end
    end
    methods
        % constructor
        function testCase = OptickleReferenceTest()
            % it's OK if you are doing reference type and your calc path is
            % the same as what is in the current path... otherwise there
            % shouldn't be anything in the current path
            
            if exist('Optickle','file')==2
                % Optickle is in the path
                if ~ ( strcmp(GetFullPath([testCase.config.calculationPath '/@Optickle/Optickle.m']),...
                              GetFullPath(which('Optickle')))...
                       && ...
                       strcmp(testCase.config.referenceType,'Files') )
                    % you have optickle in the path, but it is different
                    % from the calculation path, or you are doing a true
                    % path comparison, this is bad
                    
                    error('You have Optickle in the path, this can potentially conflict with the code you are testing, remove Optickle from your path and try again')
                end
            end
        end
        function saveTestFunctionOutputToReference(testCase)
            
            if ~strcmp(testCase.config.referenceType,'Files')
                error('cannot save unless config.referenceType is Files')
            end
            
            testPath = testCase.config.referencePath;
            fileNameBase = [testPath '/' func2str(testCase.testFunctionHandle)];
            
            output = testCase.testFunctionHandle(); %#ok<NASGU>
            
            % get the git hash id
            [retCode,retString] = system('git rev-parse HEAD');
            gitHash = 'unknown!';
            if ~retCode
                gitHash = retString;
            end
            
            % write metadata
            textFileID = fopen([fileNameBase '.txt'],'w');
            fprintf(textFileID,'Optickle test reference data\n');
            fprintf(textFileID,'----------------------------\n');
            fprintf(textFileID,['Test function: ' func2str(testCase.testFunctionHandle) '\n']);
            fprintf(textFileID,['Path to Optickle: ' testCase.optickleLocation '\n']);
            fprintf(textFileID,['Run on: ' datestr(now) '\n']);
            fprintf(textFileID,['Git hash ID: ' gitHash '\n']);
            fclose(textFileID);
            
            save([fileNameBase '.mat'],'-struct','output')
        end
        function verifyCalcAndRefMatrices(testCase,label, fieldNames)
            funHandle = @() testCase.warnOnMatrixFieldsInequalityInStruct(...
                label, fieldNames);
            
            testCase.verifyWarningFree(funHandle,@testCase.saveDataToDisk);
        end
        function warnOnMatrixFieldsInequalityInStruct(testCase,label, fieldNames)
            % precision is the product of these two numbers
            errorThreshold = testCase.config.errorThreshold;
            smallNumber = testCase.config.residualSize;
            
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
        function saveDataToDisk(testCase)
            % used as diagnostic when test fails.
            temporaryFile = tempname;
            calcStruct = testCase.calculatedStruct; %#ok<NASGU>
            refStruct = testCase.referenceStruct; %#ok<NASGU>
            save(temporaryFile, 'calcStruct', 'refStruct');
            global optickleTestResultsFile
            optickleTestResultsFile = temporaryFile;
            fprintf('<a href="matlab:load(''%s'')">Load data into workspace</a>\n', temporaryFile);
        end
    end % methods
end