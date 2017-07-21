function err = setSense_Keithley(device, mode, varargin)
    input = inputParser;
    addRequired(input,'device');
    addRequired(input,'mode',@(x) any(validatestring(upper(x),{'I','V'})));
    addParameter(input,'integrationRate',1,@(x) isnumeric(x) && isscalar(x) && x>=0.01 && x<=10);
    addParameter(input,'complianceLevel',1,@(x) isnumeric(x) && isscalar(x) && x<=20);
    addParameter(input,'autoRange',1,@(x) isnumeric(x) && isscalar(x) && (x==1 || x==0));
    addParameter(input,'range',1,@(x) isnumeric(x) && isscalar(x) && x<=20);
    parse(input,device,mode,varargin{:});
    
    integrationRate = input.Results.integrationRate;
    complianceLevel = input.Results.complianceLevel;
    autoRange = con_a_b(input.Results.autoRange,'ON','OFF');
    range = input.Results.range;
    
    err = 0;
    switch upper(mode)
        case 'I'
            %fprintf(device,':SOUR:FUNC:MODE CURR');                 % Specify functions to enable (VOLTage[:DC], CURRent[:DC], or RESistance).
            fprintf(device,':SENS:FUNC "CURR"');
            fprintf(device,':SENS:FUNC:CONC ON');                   % Enable or disable ability to measure more than one function simultaneously. When disabled, volts function is enabled.
        
            fprintf(device,[':SENS:CURR:NPLC ',num2str(integrationRate)]); % Specify integration rate (in line cycles): 0.01 to 10.
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % IMPORTANT: if the unit goes into compliance, 
            % adjust the compliance or the range value
            fprintf(device,[':SENS:CURR:PROT:LEV ', num2str(complianceLevel)]); % Specify voltage limit for I-Source. voltage compliance
            
            fprintf(device,[':SENS:CURR:RANG:AUTO ', autoRange]);  % Enable or disable auto range.
            if ~input.Results.autoRange
                fprintf(device,[':SENS:CURR:RANG ',num2str(range)]);    % Select range by specifying the expected voltage reading. volt measurement range
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case 'V'
            fprintf(device,':SENS:FUNC "VOLT"');                    % Specify functions to enable (VOLTage[:DC], CURRent[:DC], or RESistance).
            fprintf(device,':SENS:FUNC:CONC ON');                   % Enable or disable ability to measure more than one function simultaneously. When disabled, volts function is enabled.

            fprintf(device,[':SENS:VOLT:NPLC ',num2str(integrationRate)]); % Specify integration rate (in line cycles): 0.01 to 10.
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % IMPORTANT: if the unit goes into compliance, 
            % adjust the compliance or the range value
            fprintf(device,[':SENS:VOLT:PROT:LEV ', num2str(complianceLevel)]); % Specify voltage limit for I-Source. voltage compliance
            
            fprintf(device,[':SENS:VOLT:RANG:AUTO ', autoRange]);  % Enable or disable auto range.
            if ~input.Results.autoRange
                fprintf(device,[':SENS:VOLT:RANG ',num2str(range)]);      % Select range by specifying the expected voltage reading. volt measurement range
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case 'R'
            fprintf(device,':SENS:FUNC "RES"');                     % Specify functions to enable (VOLTage[:DC], CURRent[:DC], or RESistance).
            fprintf(device,':SENS:FUNC:CONC ON');                   % Enable or disable ability to measure more than one function simultaneously. When disabled, volts function is enabled.
            
            fprintf(device,[':SENS:RES:NPLC ',num2str(integrationRate)]);  % Specify integration rate (in line cycles): 0.01 to 10.
            
             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % IMPORTANT: if the unit goes into compliance, 
            % adjust the compliance or the range value
            
            fprintf(device,[':SENS:RES:RANG:AUTO ', autoRange]);  % Enable or disable auto range.
            if ~input.Results.autoRange
                fprintf(device,[':SENS:RES:RANG ',num2str(range)]);      % Select range by specifying the expected voltage reading. volt measurement range
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end 
end

