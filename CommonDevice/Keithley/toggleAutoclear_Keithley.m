function err = toggleAutoclear_Keithley(device, varargin)
    input = inputParser;
    addRequired(input,'device');
    addOptional(input,'state','off',@(x) any(validatestring(lower(x),{'on','off'})));
    parse(input,device,varargin{:});

    err = 0;
    try
        fprintf(device,[':SOUR:CLE:AUTO ',upper(input.Results.state)]);
    catch E
        disp(E.message);
        fE = mfilename('fullpath');
        [~,fN] = fileparts(fE);
        errordlg(['Error in function ',fN]);
        err = 1;
        return;
    end
end

