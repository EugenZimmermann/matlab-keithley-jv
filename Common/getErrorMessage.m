function errMsg = getErrorMessage(errKey,varargin)
% return error message for specific error key value
% This function returns a detailed error message for an unique error key value.

% INPUT:
%   errKey: error key
%   varargin: additional information about original function requesting the error message
%
% OUTPUT:
%   errMsg: error message to corresponding error key
%
% Tested: Matlab 2015b, Win10
% Author: Eugen Zimmermann, Konstanz, (C) 2016 eugen.zimmermann@uni-konstanz.de
% Last Modified on 2016-06-23

    E.position      = '\nWhile setting the ''Position'' property of ''%s'': \n-> Value must be numeric. \n-> Value must be a two to four element array. \n-> Value must be positive.';
    E.serialPorts   = '\nWhile setting ''serialPorts'' property of ''%s'': \n-> Value must be ''COM[0-9]+'' for Windows. \n-> Value must be ''/dev/ttyS[0-9]+'' for Linux.';
    E.generalPort   = '\nWhile setting a general port property of ''%s'': \n-> Value must be ''COM[0-9]+'' for a serial connection on Windows. \n-> Value must be ''/dev/ttyS[0-9]+'' for a serial connection on for Linux. \n-> Value must be numeric and scalar for an GPIB connection.';
    E.serialPort    = '\nWhile setting ''serialPort'' property of ''%s'': \n-> Value must be ''COM[0-9]+'' for Windows. \n-> Value must be ''/dev/ttyS[0-9]+'' for Linux.';
    E.gpibPort      = '\nWhile setting ''gpibPort'' property of ''%s'': \n-> Value must be numeric and scalar.';
    E.connectionType = '\nWhile setting ''connetionType'' property of ''%s'': \n-> Value must be ''serial'' or ''gpib''';
    
    E.deviceNotFound = '%s not found on port: %s  \nfound instead: ... %s';
    E.deviceNotConnected = 'Device %s not connected!';
    
    E.boolean = '\nWhile setting a ''state'' property of ''%s'': \n-> Value must be numeric (0 or 1), or logical (false or true).';
    E.temperature = '\nWhile setting a ''temperature'' property of ''%s'': \n-> Value must be numeric and in the range of 0 to 320 K.';
    E.tries = '\nWhile setting a ''tries'' property of ''%s'': \n-> Value must be numeric and in the range of 0 to 10.';
    
    E.keithleySetV = '\nWhile setting a voltage property of ''%s'': \n-> Value must be numeric and in the range of -20 to 20 V.';
    E.keithleySetMultV = E.keithleySetV;
    E.keithleySetStepV = '\nWhile setting a voltage step property of ''%s'': \n-> Value must be numeric and in the range of 0.001 to 5 V.';
    E.keithleyDelay = '\nWhile setting a time property of ''%s'': \n-> Value must be numeric and in the range of 0 to 9999 s.';
    E.keithleyDelayMult = E.keithleyDelay;
    E.keithleyIntegrationRate = '\nWhile setting the ''integrationRate'' property of ''%s'': \n-> Value must be numeric and in the range of 0.01 to 10.';
    E.keithleySpacing = '\nWhile setting the ''spacing'' property of ''%s'': \n-> Value must be ''LIN'' or ''LOG''.';

    E.keithleySetSourceV = '\nCould not set Voltage as source in %s!';
    E.keithleySetIntegrationRate = '\nCould not set integration rate in %s!';
    
    E.fwsAbsPos = '\nWhile setting a absolute position property of ''%s'': \n-> Value must be numeric and in the range of 0 to 4096 steps.';
    E.fwsRelPos = '\nWhile setting a relative position property of ''%s'': \n-> Value must be numeric and in the range of 0 to 4096 steps.';
    
    try
        if nargin > 1
            errMsg = sprintf(E.(errKey),varargin{1});
        else
            errMsg = E.(errKey);
        end
    catch e
        errMsg = e.message;
    end
end

