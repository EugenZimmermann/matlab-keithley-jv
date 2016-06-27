function [status,result] = check_string(string,condition)
% check if given value is valid string for given condition: double/string/1D cell, string
% This function checks if given value valid string for given condition.
% INPUT:
%   string: String, or 1D cell containing a string.
%   condition: Condition to be matched: "nospecial", "filename", or "email".
%
% OUTPUT:
%   result: (Converted) string value of input.
%	status: 1 if string is valid for chosen condition

% Tested: Matlab 2014a, 2014b, 2015a, Win8
% Author: Eugen Zimmermann, Konstanz, (C) 2015 eugen.zimmermann@uni-konstanz.de
    status = 1;
    result = '';
    try
        if iscell(string)
            string = string{1};
        end
        
        if ~ischar(string)
            errordlg('Input is not a string!', 'Error')
            result = -666;
            return;
        end
        
        switch lower(condition)
            case {'nospecial','filename'}
                status = isempty(regexp(string, '[^\d\w~!@#$%^&_-+(){}. '',;=[]]','ONCE'));
                if ~status
                    errordlg('Special characters except "~!@#$%^&_-+(){}.'',;=[]" are not allowed for filename!', 'Error')
                    result = -99;
                    return;
                end
            case 'folder'
                status = isempty(regexp(string, '[^\d\w~!@#$%^&()_-{}. ''+:\\,;=[]]','ONCE'));
                if ~status
                    errordlg('Special characters except "~!@#$%^&()_-{}.''+,;=[]" are not allowed for foldername!', 'Error')
                    result = -88;
                    return;
                end
            case 'email'
                email = '[a-z_-.]+@[a-z_-]+\.(com|net|de|org)';
                status = regexp(string,email,'match');
                if ~status
                    errordlg(['Input ',email,' is not a valid eMail!'], 'Error')
                    result = -77;
                    return;
                end
            otherwise
                disp('check_string skipped due to wrong condition!')
        end

        result = string;
    catch error
        errordlg(['Error in check_string for input arguments string ',string,' and condition', condition,'.']);
        disp(error.identifier)
        disp(error.message)
        
        result = -777;
        status = 0;
    end
end

