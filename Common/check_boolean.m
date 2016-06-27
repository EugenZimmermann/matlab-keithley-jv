function [result,status] = check_boolean(value)
% check if given value is boolean: double/string/1D cell
% This function checks if given value is a boolean.
% INPUT:
%   string: String, a 1D cell containing a string, or a double value.
%
% OUTPUT:
%   result: (Converted) numeric value (0 or 1) of input.
%	status: 1 if string is valid for chosen condition

% Tested: Matlab 2014a, 2014b, 2015a, Win8
% Author: Eugen Zimmermann, Konstanz, (C) 2015 eugen.zimmermann@uni-konstanz.de
    result = 0;
    status = 1;
    try
        if iscell(value)
            value = value{1};
        end
        
        try
            if logical(value)
                result = con_a_b(value,1,0);
                return;
            end
        catch error
        end

        if ischar(value)
            temp_port = regexpi(value,'(^true|^false|^[0-9])','match');
            switch temp_port{1}
                case 'true'
                    result = 1;
                case 'false'
                    result = 0;
                case {'0','1'}
                    result = con_a_b(strcmp(temp_port,'1'),1,0);
                otherwise
                    status = 0;
            end
        elseif isnumeric(value) && ~isnan(value)
            switch value
                case {0,1}
                    result = value;
                otherwise
                    status = 0;
            end
        else
            status = 0;
        end
        
        if ~status
            errordlg('Value can be ''true/1'' or ''false/0''.', 'Error')
        end
    catch error
        errordlg(['Error in check_boolean for input argument ',value,'.']);
        disp(error.identifier)
        disp(error.message)
        status = 0;
    end
end

