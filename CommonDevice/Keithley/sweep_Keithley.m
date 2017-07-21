function err = sweep_Keithley(device, mode, start, stop, step, varargin)
    input = inputParser;
    addRequired(input,'device');
    addRequired(input,'mode',@(x) any(validatestring(upper(x),{'I','V'})));
    addRequired(input,'start',@(x) isnumeric(x) && isscalar(x) && abs(x)<=20);
    addRequired(input,'stop',@(x) isnumeric(x) && isscalar(x) && abs(x)<=20);
    addRequired(input,'step',@(x) isnumeric(x) && isscalar(x) && abs(x)>=0.001 && abs(x)<=5);
    addParameter(input,'spacing','LIN',@(x) any(validatestring(x,{'LIN','LOG'})));
    parse(input,device,mode,start,stop,step,varargin{:})
    
    err = 0;
    try
        lengthRange = length(min(start,stop):abs(step):max(start,stop));
        assert(lengthRange<2500,'Number of sweep points exceeds internal storage of Keithley! Extend functionality, or reduce number of points.') 

        switch upper(mode)
            case 'I'
                fprintf(device,[':SOUR:CURR:STAR ',num2str(start)]);    % Specify start level for I-sweep.
                fprintf(device,[':SOUR:CURR:STOP ',num2str(stop)]);     % Specify stop level for I-sweep.
                fprintf(device,[':SOUR:CURR:STEP ',num2str(step)]);     % Specify step value for I-sweep.

                fprintf(device,':SOUR:CURR:MODE SWE');     % Select I-Source mode (FIXed, SWEep, or LIST).
            case 'V'
                fprintf(device,[':SOUR:VOLT:STAR ',num2str(start)]);
                fprintf(device,[':SOUR:VOLT:STOP ',num2str(stop)]);
                fprintf(device,[':SOUR:VOLT:STEP ',num2str(step)]);

                fprintf(device,':SOUR:VOLT:MODE SWE');
        end

        %# set sweep spacing type (LINear or LOGarithmic).
        fprintf(device,[':SOUR:SWE:SPAC ', input.Results.spacing]);      
        
        %# set trigger counts (must be = # sweep points)
        fprintf(device,':TRIG:COUN %s', num2str(lengthRange));
    catch E
        disp(E.message);
        fE = mfilename('fullpath');
        [~,fN] = fileparts(fE);
        errordlg(['Error in function ',fN]);
        err = 1;
        return;
    end
end

