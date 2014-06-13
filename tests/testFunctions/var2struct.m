function s = var2struct(varargin)
    % stores the input variables into a structure where the fields inherit
    % the variable names.
    names = arrayfun(@inputname,1:nargin,'UniformOutput',false);
    s = cell2struct(varargin,names,2);
end
