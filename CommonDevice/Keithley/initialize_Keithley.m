function device = initialize_Keithley(connectionType, port)
    input = inputParser;
    addRequired(input,'connectionType',@(x) any(validatestring(lower(x),{'serial','gpib'})));
    addRequired(input,'port',@(x) (ischar(x) && strfind(x,'COM')) || (isnumeric(x) && isscalar(x) && ~isnan(x)));
    parse(input,connectionType,port);

    switch lower(connectionType)
        case 'serial'
            device = instrfind('Type', 'serial', 'Port', port, 'Tag', '');
            if isempty(device)
                device = serial(port, 'Terminator', {'CR','CR'}, 'BaudRate', 57600);
            else
                fclose(device);
                device = device(1);
            end

            % Set the property values.
            set(device, 'ByteOrder', 'littleEndian');
            set(device, 'ErrorFcn', '');
            set(device, 'InputBufferSize', 100000);
            set(device, 'Name', 'Keithley2400_Serial');
            set(device, 'OutputBufferSize', 100000);
            set(device, 'OutputEmptyFcn', '');
            set(device, 'Tag', '');
            set(device, 'Timeout', 10);
            set(device, 'UserData', []);

        case 'gpib'
            device = instrfind('Type', 'gpib', 'BoardIndex', 0, 'PrimaryAddress', port, 'Tag', '');
            if isempty(device)
                device = gpib('NI', 0, port);
            else
                fclose(device);
                device = device(1);
            end

            % Set the property values.
            set(device, 'BoardIndex', 0);
            set(device, 'ByteOrder', 'littleEndian');
            set(device, 'BytesAvailableFcnMode', 'eosCharCode');
            set(device, 'CompareBits', 8);
            set(device, 'EOIMode', 'on');
            set(device, 'EOSCharCode', 'CR');
            set(device, 'EOSMode', 'read&write');
            set(device, 'ErrorFcn', '');
            set(device, 'InputBufferSize', 100000);
            set(device, 'Name', 'Keithley2400_GPIB');
            set(device, 'OutputBufferSize', 100000);
            set(device, 'OutputEmptyFcn', '');
            set(device, 'SecondaryAddress', 0);
            set(device, 'Tag', '');
            set(device, 'Timeout', 10);
            set(device, 'UserData', []);
    end

    %# set Terminator to device settings
    set(device, 'Timeout', 2);

    %# Connect to instrument object, obj1.
    fopen(device);

    fprintf(device,':*RST');                % Return SourceMeter to GPIB defaults
    fprintf(device,':*CLS');                % Clears all event registers and Error Queue.

    fprintf(device, ':SYST:BEEP:STAT OFF');
end

