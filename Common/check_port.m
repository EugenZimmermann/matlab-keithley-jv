function [result,status] = check_port(value)
% check if given value is serial port: double/string/1D cell
% This function checks if given value corresponds to a valid port description.
% INPUT:
%   string: String, a 1D cell containing a string, or a double value.
%
% OUTPUT:
%   result: (Converted) string value PORTXY of input.
%	status: 1 if string is valid for chosen condition

% Tested: Matlab 2014a, 2014b, 2015a, Win8
% Author: Eugen Zimmermann, Konstanz, (C) 2015 eugen.zimmermann@uni-konstanz.de
% Last Modified on 2015-11-12

    result = 0;
    status = 1;
    try
        if iscell(value)
            value = value{1};
        end

        if ischar(value)
            temp_port = regexpi(value,'(^COM[0-9]+|^[0-9]+)','match');
            if ~isempty(regexpi(value,'^COM[0-9]+','match'))
                result = upper(temp_port);
            elseif ~isempty(regexpi(value,'^[0-9]+','match'))
                [result,status] = check_value(temp_port,0,255);
                if status
                    result = ['COM',num2str(result)];
                    return;
                end
            else
                status = 0;
            end
        elseif isnumeric(value) && ~isnan(value)
            [result,status] = check_value(value,0,255);
            if status
                result = ['COM',num2str(result)];
                return;
            end
        else
            status = 0;
        end
        
        if ~status
            errordlg('Port can be ''COM#'' or ''#'' with numeric values between 1 and 255.', 'Error')
        end
    catch error
        errordlg(['Error in check_port for input argument ',value,'.']);
        disp(error.identifier)
        disp(error.message)
        status = 0;
    end
end

