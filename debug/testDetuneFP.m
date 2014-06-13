function exitCond = testDetuneFP(referenceStruct, calculationStruct)
    exitCond = 0;
    
    
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
    % precision is the product of these two numbers
    errorThreshold = 1e-6;
    smallNumber = 1e-6;

    for name = fieldNames
        try
            calcMat = abs(calcStruct.(name{:}));
            refMat = abs(refStruct.(name{:}));
            
            small = max(calcMat(:))*smallNumber;
            
            errorMat = (calcMat-refMat)./(calcMat+refMat+small);
            
            error = max(errorMat(:));
            
            if error > errorThreshold
                
                dim = length(size(errorMat));
                
                % find the index of the error
                [ind{1:dim}] = ind2sub(size(errorMat),find(errorMat == max(errorMat(:))));
                
                warning([label ' error is ' num2str(error) ' at index '...
                    cell2CommaSeparatedString(ind) ' in variable ' name{:}])
                errorCount = errorCount + 1;
            end
        catch err
            warning(['Error occurred while calculating ' label ' calculation error: ' err.message])
            errorCount = errorCount + 1;
        end
    end

end

function stringOut = cell2CommaSeparatedString(cellIn)
    stringOut = '';
    for jj = 1:length(cellIn)
        stringOut = [stringOut num2str(cellIn{jj}) ', '];
    end
    stringOut = stringOut(1:end-2);

end