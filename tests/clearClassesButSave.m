function clearClassesButSave(varargin)
    % This function will allow you to clear classes in the calling
    % workspace, but save some variables.
    %
    % example usage:
    % clearClassesButSave(var1, var2, var3, ...)
    
    fileName = [tempname '.mat'];
    
    arginStruct = cell2struct(varargin,arrayfun(@inputname,1:nargin,'UniformOutput',false),2);
    
    save(fileName,'-struct','arginStruct')
    evalin('caller','clear classes')
    
    loadedStruct = load(fileName);
    
    varCell = struct2cell(loadedStruct);
    fieldNames = fieldnames(loadedStruct);
    
    % cellfun doesn't work because 'caller' is inside anonymous function
    for j = 1:length(fieldNames)
        assignin('caller',fieldNames{j},varCell{j});
    end
end