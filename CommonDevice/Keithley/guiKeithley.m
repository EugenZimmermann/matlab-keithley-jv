function [deviceClass,deviceGUI,guiElements] = guiKeithley(parent,varargin)
    input = inputParser;
    addRequired(input,'parent');
    addParameter(input,'fontsize',0,@(x) isstruct(x) && isfield(x,'general'));
    addParameter(input,'style',0,@(x) isstruct(x) && isfield(x,'color'));
    addParameter(input,'name','Keithley',@(x) ischar(x) && ~isempty(x));
    addParameter(input,'position',[5 5],@(x) isnumeric(x) && length(x)==2);
    addParameter(input,'log','',@(x) isstruct(x) && isfield(x,'update'));
    addParameter(input,'SerialPorts',{},@(x) iscell(x));
    parse(input,parent,varargin{:});
    
    try
        if ~isstruct(input.Results.log)
            log.update = @objLogFallback;
            log.update('Log not specified. Use fallback.');
        else
            log = input.Results.log;
        end
    catch e
        disp(e.message)
        log.update = @(x) disp(x);
    end
    
    name = input.Results.name(1:min(length(input.Results.name),20));
        
    position = input.Results.position;
        
    try
        if ~isstruct(input.Results.fontsize)
            tempGUI = initializeGUI();
            fontsize = tempGUI.fontsize;
            style = tempGUI.style;
        else
            fontsize = input.Results.fontsize;
        end
    catch e
        disp(e.message)
        fontsize = struct();
        fontsize.general    = 11;
        fontsize.dir        = 10;
        fontsize.bigtext    = 18;
        fontsize.btn        = 12;
        fontsize.smallbtn   =  8;
        fontsize.label      = 14;
    end
    
    try
        if exist('style','var') && isstruct(style) && isfield(style,'color')
            % nothing to do
        elseif ~isstruct(input.Results.style)
            tempGUI = initializeGUI();
            style = tempGUI.style;
        else
            style = input.Results.style;
        end
    catch e
        disp(e.message)
        z = 255;
        style.color     = {[176/z   0/z   0/z],[255/z 100/z 100/z],[236/z 106/z 170/z],[228/z 106/z 236/z],[134/z  77/z 230/z],...
                           [  0/z   0/z 176/z],[ 69/z  77/z 227/z],[ 69/z 162/z 227/z],[103/z 222/z 226/z],[103/z 226/z 175/z],...
                           [109/z 226/z 103/z],[169/z 226/z 103/z],[219/z 226/z 103/z],[241/z 162/z  85/z],[244/z 121/z  55/z],...
                           [169/z 169/z 169/z],[90/z,90/z,90/z]};
    end
    
    %# get all serial ports
    if isempty(input.Results.SerialPorts)
        HardwareInfo = instrhwinfo('serial');
        SerialPorts = HardwareInfo.SerialPorts;
    else
        SerialPorts = input.Results.SerialPorts;
    end
    
    if size(SerialPorts)>0
        SerialPortsString = sprintf([repmat('%s|',1,length(SerialPorts)-1),'%s'],SerialPorts{:});  
    else
        SerialPortsString = 'none';
        log.update('No serial ports found');
    end

    %# private variables of device
    port = '';
    
    %# data elements of device
    deviceGUI = struct();
    deviceClass = classKeithley2400();
    
    %# fallback values in case preference file is broken
    deviceGUI.defaultS.Port = 'COM3';
    deviceGUI.defaultS.GPIBPort = 24;
    deviceGUI.defaultS.ConnectionType = 'GPIB';
    deviceGUI.defaultS.Spacing = 'LIN'; % 'LIN' or 'LOG' spacing between measurement points of sweep
        
    %# gui elements of device
    position = [position(1) position(2) 210 155];
    guiElements.Panel = gui_panel(parent,position,name,fontsize.general,['uiStatus',name]);
        guiElements.drop = gui_drop(guiElements.Panel, [150 5 55 22.5], '',['dropStatus',name], {@onPortSelection});
            set(guiElements.drop,'String',SerialPortsString,'Value',1);
        guiElements.tbtn = gui_tbtn(guiElements.Panel,[5 5 140 25],'connect',fontsize.btn,'connect/disconnect from device','btnConnect',{@onConnect});
            set(guiElements.tbtn,'Value',0,'FontWeight','bold','BackgroundColor',style.color{1})
            
        DeviceColumns     = {'Variable', 'Value'};
        DeviceFormat      = {'bank', 'bank'};
        DeviceEditable    = [false, true];
        DeviceColumnWidth = {99,99};
        guiElements.table  = gui_table(guiElements.Panel,[5 35 position(3)-10 position(4)-60],DeviceColumns,DeviceFormat,DeviceColumnWidth,DeviceEditable,[],['table',name],{@onTableEdit});
        
    %# create menuepoint of device
    guiElements.menu = uimenu(ancestor(parent,'figure','toplevel'),'Label',name,'ForegroundColor',style.color{end});
        guiElements.loadPrefs = uimenu(guiElements.menu,'Label','load preferences','Callback',@loadSettings);
        guiElements.savePrefs = uimenu(guiElements.menu,'Label','save preferences','Callback',@saveSettings);
        guiElements.reset = uimenu(guiElements.menu,'Label','reset','ForegroundColor','red','Callback',@reset);
        
    %# device functions
    deviceGUI.reset = @reset;
    deviceGUI.connect = @manConnect;
    deviceGUI.getSettings = @getSettings;

    function reset(varargin)
        if deviceClass.getConnectionStatus()
            deviceClass.disconnect();
        end
        
        loadSettings();
        
        table_fields = fieldnames(deviceGUI.default);
        table_variables = cellfun(@(s) num2str(s),struct2cell(deviceGUI.default),'UniformOutput',false);
        table_data = horzcat(table_fields,table_variables);
        guiElements.table.Data = table_data;
        
        if iscell(SerialPorts) && ~isempty(SerialPorts)
            [~,b] = ismember(deviceGUI.default.Port,SerialPorts);
            if b
                port = SerialPorts{b};
                guiElements.drop.Value = b;
            else
                log.update([name,': Default port not found.']);
                port = SerialPorts{1};
                guiElements.drop.Value = 1;
            end
        end
    end

    function settings = getSettings()
        settings = cell2struct(guiElements.table.Data(:,2),fieldnames(deviceGUI.default),1);
        settings.GPIBPort = str2double(settings.GPIBPort);
    end

    function loadSettings()
        try
            [pref_temp,pref_err] = loadPreferences(name,log);
            if pref_err
                log.update(['Loading preferences failed. File not existing or damaged. Creating new preference file for ',name,' ...'])
                deviceGUI.default = deviceGUI.defaultS;
                savePreferences(name,deviceGUI.defaultS,log);
                log.update(['Creating ',name,'.ini done.'])
            else
                deviceGUI.default = pref_temp;
            end
        catch error
            log.update(error.message)
            deviceGUI.default = deviceGUI.defaultS;
            savePreferences(name,deviceGUI.defaultS,log);
        end
    end

    function saveSettings()
        savePreferences(name,getSettings(),log);
    end

    function selectPort(selected)
        port = selected;
    end

    function onPortSelection(hObject,~)
        contents = cellstr(hObject.String);
        selectPort(contents{hObject.Value});
    end

    % connect
    function onConnect(~,~)
        if guiElements.tbtn.Value
            settings = getSettings();
            deviceClass.setConnectionType(settings.ConnectionType);
            deviceClass.setPort(con_a_b(strcmpi(settings.ConnectionType,'serial'),port,settings.GPIBPort));
            deviceClass.connect()
            if isempty(deviceClass.getConnectionStatus()) || ~deviceClass.getConnectionStatus()
                guiElements.tbtn.Value = 0;
            else
                log.update(['connected to ',deviceClass.defaultID])
            end
        else
            deviceClass.disconnect();
        end
        guiElements.menu.ForegroundColor = con_a_b(guiElements.tbtn.Value,style.color{11},style.color{end});
        guiElements.tbtn.String = con_a_b(guiElements.tbtn.Value,'connected','connect');
        guiElements.tbtn.BackgroundColor = con_a_b(guiElements.tbtn.Value,style.color{11},style.color{1});
        guiElements.drop.Enable = con_a_b(guiElements.tbtn.Value,'off','on');
    end

    % manual connect
    function manConnect(state)
        guiElements.tbtn.Value = state;
        onConnect();        
    end

    function onTableEdit(hObject,action)
        temp = hObject.Data;  
        switch(temp{action.Indices(1),1})
            case 'Port'
                [result,status] = check_port(action.NewData);
                hObject.Data(action.Indices(1),action.Indices(2)) = con_a_b(status,{result},{action.PreviousData});
            case 'GPIBPort'
                [result,status] = check_value(action.NewData,0,100);
                hObject.Data(action.Indices(1),action.Indices(2)) = con_a_b(status,{num2str(round(result))},{action.PreviousData});
            case 'ConnectionType'
                temp_port = regexpi(action.NewData,'(Serial|GPIB)','match');
                if ~isempty(temp_port)
                    hObject.Data(action.Indices(1),action.Indices(2)) = lower(temp_port);
                else
                    hObject.Data(action.Indices(1),action.Indices(2)) = {action.PreviousData};
                    errordlg('ConnectionType can only be serial or GPIB. Serial connection is NOT supported by most measurement functions.', 'Error')
                end
            case 'DelayTimeIV'
                [result,status] = check_value(action.NewData,0,3600);
                hObject.Data(action.Indices(1),action.Indices(2)) = con_a_b(status,{num2str(round(result))},{action.PreviousData});
            case 'IntegrationRate'
                [result,status] = check_value(action.NewData,0.01,10);
                hObject.Data(action.Indices(1),action.Indices(2)) = con_a_b(status,{num2str(round(result))},{action.PreviousData});
            case 'Spacing'
                temp_port = regexpi(action.NewData,'(LIN|LOG)','match');
                if ~isempty(temp_port)
                    hObject.Data(action.Indices(1),action.Indices(2)) = upper(temp_port);
                else
                    hObject.Data(action.Indices(1),action.Indices(2)) = {action.PreviousData};
                    errordlg('Spacing can only be LINear or LOGarithmic', 'Error')
                end
            case {'MinV','MaxV'}
                ind_min = find(ismember(hObject.Data(:,1),'MinV'));
                ind_max = find(ismember(hObject.Data(:,1),'MaxV'));
                
            	[result_min,status_min] = check_value(hObject.Data(ind_min,2),-10,10);
                [result_max,status_max] = check_value(hObject.Data(ind_max,2),-10,10);

                if status_min && status_max && result_min<result_max
                    hObject.Data(ind_min,2) = {num2str(result_min)};
                    hObject.Data(ind_max,2) = {num2str(result_max)};
                else
                    if result_min>result_max
                        errordlg('Start voltage has to be smaller than end voltage. Adjust scan-direction with buttons.', 'Error')
                    end
                    hObject.Data(action.Indices(1),action.Indices(2)) = {action.PreviousData};
                end
            case 'StepsizeV'
                [result,status] = check_value(action.NewData,0.00001,2);
                hObject.Data(action.Indices(1),action.Indices(2)) = con_a_b(status,{num2str(round(result))},{action.PreviousData});
            otherwise
                hObject.Data(action.Indices(1),action.Indices(2)) = {action.PreviousData};
                log.update(['Unknown variable in ',name,' prefs.'])
        end
        saveSettings();
    end
end