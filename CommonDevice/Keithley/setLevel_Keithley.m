function err = setLevel_Keithley(device, mode, varargin)
    input = inputParser;
    addRequired(input,'device');
    addRequired(input,'mode',@(x) any(validatestring(upper(x),{'I','V'})));
    addOptional(input,'level',0,@(x) isnumeric(x) && isscalar(x) && x>=0 && x<=20);
    parse(input,device, mode, varargin{:});
    
    err = 0;
    try
        switch upper(mode)
            case 'I'
                fprintf(device,['SOUR:CURR:LEV ',num2str(input.Results.level)]);
            case 'V'
                fprintf(device,['SOUR:VOLT:LEV ',num2str(input.Results.level)]);
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