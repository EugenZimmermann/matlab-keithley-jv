function validFcn = validationFcn(fcnKey,fcnName)
% return validation function for specific function key value
% This function returns a presetted validation function for an unique validation function key value.

% INPUT:
%   fcnKey: function key
%   varargin: additional information about original function requesting the validation function
%
% OUTPUT:
%   validFcn: validation function to corresponding function key
%
% Tested: Matlab 2015b, Win10
% Author: Eugen Zimmermann, Konstanz, (C) 2016 eugen.zimmermann@uni-konstanz.de
% Last Modified on 2016-06-23

    fcn.position    = @(x) assert(isnumeric(x) && ~sum(isnan(x)) && length(x)<=4 && length(x)>=2 && min(size(x))==1,getErrorMessage(fcnKey,fcnName));
    
    fcn.serialPorts = @(x) assert(sum(cellfun(@(s)~isempty(regexpi(s,'(^COM[0-9]+$|^/dev/ttyS[0-9]+$)')),x,'UniformOutput',true))==length(x),getErrorMessage(fcnKey,fcnName));
    fcn.generalPort = @(x) assert(~isempty(regexpi(num2str(x),'(^COM[0-9]+$|^/dev/ttyS[0-9]+$|^[0-9]+$)')),getErrorMessage(fcnKey,fcnName));
    fcn.serialPort  = @(x) assert(~isempty(regexpi(num2str(x),'(^COM[0-9]+$|^/dev/ttyS[0-9]+$)')),getErrorMessage(fcnKey,fcnName));
    fcn.gpibPort    = @(x) assert(isnumeric(x) && isscalar(x) && (x > 0) && (x<256),getErrorMessage(fcnKey,fcnName));
    fcn.connectionType = @(x) assert(~isempty(regexpi(x,'^serial$|^gpib$')),getErrorMessage(fcnKey,fcnName));
    
    fcn.boolean     = @(x) assert((isnumeric(x) && isscalar(x) && (x==1||x==0))|islogical(x));
    fcn.temperature = @(x) assert(isnumeric(x) && isscalar(x) && x>=0 && x<=320,getErrorMessage(fcnKey,fcnName));
    fcn.tries       = @(x) assert(isnumeric(x) && isscalar(x) && x>=0 && x<=10,getErrorMessage(fcnKey,fcnName));
    
    fcn.keithleySetV        = @(x) assert(isnumeric(x) && isscalar(x) && abs(x)<=20,getErrorMessage(fcnKey,fcnName));
    fcn.keithleySetMultV    = @(x) assert(isnumeric(x) && max(abs(x))<=20,getErrorMessage(fcnKey,fcnName));
    fcn.keithleySetStepV    = @(x) assert(isnumeric(x) && isscalar(x) && (abs(x)>=0.001 && abs(x)<=5),getErrorMessage(fcnKey,fcnName));
    fcn.keithleyDelay       = @(x) assert(isnumeric(x) && isscalar(x) && x>=0 && x<=9999,getErrorMessage(fcnKey,fcnName));
    fcn.keithleyDelayMult   = @(x) assert(isnumeric(x) && min(x)>=0 && max(x)<=9999,getErrorMessage(fcnKey,fcnName));
    fcn.keithleyIntegrationRate = @(x) assert(isnumeric(x) && isscalar(x) && x>=0.01 && x<=10,getErrorMessage(fcnKey,fcnName));   
    fcn.keithleySpacing     = @(x) assert(any(validatestring(x,{'LIN','LOG'})),getErrorMessage(fcnKey,fcnName));
    
    fcn.fwsAbsPos = @(x) assert(isnumeric(x) && isscalar(x) && x>=0 && x<=4096 && round(x)==x,getErrorMessage(fcnKey,fcnName));
    fcn.fwsRelPos = fcn.fwsAbsPos;
    
    try
        validFcn = fcn.(fcnKey);
    catch e
        assert(false,e.message);
    end
end

