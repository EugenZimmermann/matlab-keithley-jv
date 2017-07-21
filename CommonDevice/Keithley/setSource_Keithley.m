function err = setSource_Keithley(device, mode)
    input = inputParser;
    addRequired(input,'device');
    addRequired(input,'mode',@(x) any(validatestring(upper(x),{'I','V'})));
    parse(input,device,mode);
    
    % Select source mode (VOLTage, CURRent or MEMory).
    err = 0;
    try
        switch mode
            case 'I'
                fprintf(device,':SOUR:FUNC:MODE CURR');
            case 'V'
                fprintf(device,':SOUR:FUNC:MODE VOLT');
            case 'M'
                fprintf(device,':SOUR:FUNC MEM');
        end
    catch E
        disp(E.message);
        fE = mfilename('fullpath');
        [~,fN] = fileparts(fE);
        errordlg(['Error in function ',fN]);
        err = 1001;
        return;
    end
end

