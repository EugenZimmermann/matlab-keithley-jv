function [result,status] = check_value(value,start,stop)
% check if given value is between start and stop: double/string/1D cell, double, double
% This function checks a given value whether it lies between start and stop.
% INPUT:
%   value: Numeric value (Double/Integer), string, or 1D cell containing a numeric value or a string.
%   start: Numeric values a lower boundary condition.
%   stop: Numeric values a upper boundary condition.
%
% OUTPUT:
%   result: (Converted) numeric value of input
%	status: 1 if numeric value was found at all AND is between start and stop, otherwise 0

% Tested: Matlab 2014a, 2014b, 2015a, 2017a, Win8, Win10
% Author: Eugen Zimmermann, Konstanz, (C) 2015 eugen.zimmermann@uni-konstanz.de

input = inputParser;
addRequired(input,'value');
addRequired(input,'start',@(x) isnumeric(x) && isscalar(x) && ~isnan(x));
addRequired(input,'stop',@(x) isnumeric(x) && isscalar(x) && ~isnan(x));
parse(input,value,start,stop);

    try
        if iscell(value)
            value = value{1};
        end
        
        if ischar(value)
            value = str2double(strrep(value, ',', '.'));
        end

%         status = length(value)==1 && isnumeric(value) && ~isnan(value);
%         if ~status
%             errordlg('Input must be a number', 'Error')
%             result = -999;
%             return;
%         end
        
        status = value>=start && value<=stop;
        if ~status
            errordlg(['Input must be between ',num2str(start),' and ',num2str(stop)], 'Error')
            result = -888;
            return
        end

        result = value;
    catch error
        disp('Error in IVSetup\check_value');
        disp(error.identifier)
        disp(error.message)
        
        result = -777;
        status = 0;
    end
end

