function err = setDelay_Keithley(device, mode, varargin)
    input = inputParser;
    addRequired(input,'device');
    addRequired(input,'mode',@(x) any(validatestring(lower(x),{'auto','manual'})));
    addOptional(input,'time',@(x) isnumeric(x) && isscalar(x) && x>=0 && x<=9999.999);
    parse(input,device,mode,varargin{:});
    
    err = 0;
    try
        switch lower(mode)
            case 'auto'
                fprintf(device,':SOUR:DEL:AUTO ON');                            % Enable or disable auto settling (delay) time.
            case 'manual'
                fprintf(device,':SOUR:DEL:AUTO OFF');                           % Enable or disable auto settling (delay) time.
                fprintf(device,[':SOUR:DEL ', num2str(input.Results.time)]);   	% Specify settling (delay) time (in sec): 0 to 9999.999.
        end
    catch E
        disp(E.message);
        fE = mfilename('fullpath');
        [~,fN] = fileparts(fE);
        errordlg(['Error in function ',fN]);
        err = 1;
        return;
    end
end

