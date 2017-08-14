classdef classKeithley2400 < handle
% create Keithley2400 object
% This function creates a device object for a Keithley 24XX (SCPI).

% INPUT:
%   connectionType: string containing type of connection (serial or gpib)
%   port: cell array of available serial ports (strings, i.e., 'COM[0-255]', '/dev/ttyS[0-255]')
%
% OUTPUT:
%   deviceObject: handle to device object
%
% METHODS:
%   deviceObject = classKeithley2400
%	reset
%	connect
%	disconnect
%	refresh
%	connectionHandle = getConnection
%	setConnectionType
%	type = getConnectionType
%	setPort
%	[port,portSet] = getPort
%	[connectionStatus, ID] = getConnectionStatus
%	err = setOutputState
%	outputState = getOutputState
%	err = abort
%	err = abortAll
%	err = goIdle
%	err = setPointV
%	err = updatePointV
%	dataPointV = measurePointV
%	err = setSweepV
%	err = updateSweepV
% 	dataSweepV = measureSweepV
% 	dataSweepVPP = measureSweepVPP
%	dataSweepCycle = measureCycle
% 	dataSteadyStateMPP = measureSteadyState
%	dataSteadyStateJSC = measureSteadyState
%	dataSteadyStateVOC = measureSteadyState
%	err = setTimeScan
%	err = updateTimeScan
%	dataTimeScan = measureTimeScan
% 	dataTimePointV = measureTimePointV
%	dataTimeSweepV = measureTimeSweepV
%
% Tested: Matlab 2015b, Win10, NI GPIB-USB-HS+ Controller, Keithley KUSB-488B Controller, Keithley 2400, Keithley2410, Keithley2401
% Author: Eugen Zimmermann, Konstanz, (C) 2016 eugen.zimmermann@uni-konstanz.de
% Last Modified on 2016-10-14
    properties (Constant)
        Type = 'device';
        functionName = 'classKeithley2400';
        
        %# set default settings
        defaultID = 'Keithley';
        minV = 0;
        maxV = 1;
        intRate = 1;
        spacing = 'lin';
    end

    properties (Access = private)
        id
        port
        portSet
        connected
        connectionType
        connectionHandle
        abortMeasurement
        abortAllMeasurements
        outputState
        defaultSettings
    end

    methods        
		function device = classKeithley2400(varargin)
            %# get name of function
            ST = dbstack;
            functionNameTemp = ST.name;
        
            input = inputParser;
                addParameter(input,'connectionType','serial',validationFcn('connectionType',functionNameTemp))
                addParameter(input,'port','none',validationFcn('generalPort',functionNameTemp));
            parse(input,varargin{:});
            
            %# set device id to ''
            device.id = '';
            
            %# set device status to "not connected" and "output deactivated"
            device.connected = 0;
            device.outputState = 0;
            
            %# set abort triggers to clear = 0
            device.abortMeasurement = 0;
            device.abortAllMeasurements = 0;
            
            %# set port if available
            device.connectionType = input.Results.connectionType;
            if strcmpi(input.Results.port,'none')
                switch device.connectionType
                    case 'gpib'
                        device.portSet = 1;
                        device.port = 24;
                    otherwise
                        device.portSet = 0;
                        device.port = [];
                end
            else
                %# if this line throws an error, than check your port parameter
                check_port = validationFcn([device.connectionType,'Port'],functionNameTemp);
                    check_port(input.Results.port)
                
                device.portSet = 1;
                device.port = input.Results.port;
            end
        end
        
        function reset(device,varargin)
            if device.getConnectionStatus()
                device.setOutputState(0);
            end
            device.disconnect();
        end
        
        function connectionHandle = getConnection(device)
            connectionHandle = device.connectionHandle;
        end
        
        function [status,id] = getConnectionStatus(device)
            status = device.connected;
            id = device.id;
        end
        
        function setConnectionType(device,connectionType)
            input = inputParser;
                addRequired(input,'device')
                addRequired(input,'connectionType',validationFcn('connectionType',device.functionName))
            parse(input,device,connectionType);
            
            if ~strcmpi(input.Results.connectionType,device.connectionType)
                device.connectionType = input.Results.connectionType;
                device.portSet = 0;
            end
        end
        
        function type = getConnectionType(device)
            type = device.connectionType;
        end

        function setPort(device,port)
            input = inputParser;
                addRequired(input,'device')
                addRequired(input,'port',validationFcn([lower(device.connectionType),'Port'],device.functionName))
            parse(input,device,port);
            
            device.port = input.Results.port;
            device.portSet = 1;
        end
        
        function [port,portSet] = getPort(device)
            port = device.port;
            portSet = device.portSet;
        end
        
        function manConnect(device,state)
            input = inputParser;
                addRequired(input,'device')
                addRequired(input,'state',validationFcn('boolean',device.functionName))
            parse(input,device,state);
            
            if state
                device.connect();
            else
                device.disconnect();
            end
        end
        
        function refresh(device)
            device.manConnect(0);
            device.manConnect(1);
        end
        
        function connect(device)
            if device.portSet
                try
					device_temp = initialize_Keithley(device.connectionType, device.port);
					set(device_temp,'Timeout',2);
                    %# check if program is connected to correct device
                    id_temp = query(device_temp,'*IDN?');
                    device.connected = strfind(lower(id_temp),lower(device.defaultID));
                    if device.connected
                        %# assign connection handle to device object
                        device.connectionHandle = device_temp;
                        device.id = id_temp;
                        
                        %# Control auto zero (OFF = disabled; ON = enabled; ONCE = force immediate update of auto zero.)
                        %# Helpful for drifting zero as, i.e., when the device is heating up
                        fprintf(device.connectionHandle,':SYST:AZER:STAT ON');
                        
                        %# reset time at startup
                        fprintf(device.connectionHandle,':SYST:TIME:RES');

                        %# Enable/disable timestamp reset when exiting idle.
                        fprintf(device.connectionHandle,':SYST:TIME:RES:AUTO OFF');

                        %# Select timestamp format (ABSolute or DELTa).
                        fprintf(device.connectionHandle,':TRAC:TST:FORM ABS');

                        %# Specify buffer control mode (NEVER or NEXT).
                        fprintf(device.connectionHandle,':TRAC:FEED:CONT NEVER');    

                        %# enable or disable auto clear (turn output off) for source.
                        toggleAutoclear_Keithley(device.connectionHandle, 'OFF');
                        
                        disp(['connected to ',device.defaultID])
                    else
                        errordlg(sprintf(getErrorMessage('deviceNotFound'),device.defaultID,device.port,id_temp))
                        fclose(device_temp);
                        delete(device_temp);
                        return
                    end
                catch err
                    errordlg(err.message)
                    try
                        fclose(device_temp);
                        delete(device_temp);
                    catch err2
                        disp(err2.message)
                    end
                    device.connected = 0;
                    device.connectionHandle = [];
                    return
                end
            else
                helpdlg(['Please define a ',device.connectionType,'-port first.'],'Port not set')
                return
            end
        end
        
        function disconnect(device)
            try
                if isa(device.connectionHandle,'serial') || isa(device.connectionHandle,'gpib')
                    fclose(device.connectionHandle);
                    device.connectionHandle = [];
                    disp(['disconnected from ',device.defaultID])
                end
                device.connected = 0;
                device.id = '';
            catch error
                errordlg(error.message)
            end
        end
        
        function state = getOutputState(device)
            state = device.outputState;
        end
        
        function err = setOutputState(device,varargin)           
            input = inputParser;
                addRequired(input,'device')
                addOptional(input,'state',0,validationFcn('boolean',device.functionName))
            parse(input,device,varargin{:});
            
            %# check if device is connected, otherwise abort
            if ~device.connected
                err = 1;
                errordlg(sprintf(getErrorMessage('deviceNotConnected'),device.defaultID))
                return
            end
            fprintf(device.connectionHandle,':ABORt');

            %# deactivate output
            err = toggleOutput_Keithley(device.connectionHandle, con_on_off(input.Results.state));
            if ~err
                device.outputState = input.Results.state;
                device.abortMeasurement = 0;
                device.abortAllMeasurements = 0;
            end
            %# clear Trigger events
            fprintf(device.connectionHandle,':TRIGger:CLEar');
        end
        
        %# set trigger in order to abort/skip current measurement
        function err = abort(device)
            if ~device.connected
                err = 1;
                errordlg(sprintf(getErrorMessage('deviceNotConnected'),device.defaultID))
                return
            end
            device.abortMeasurement = 1;
            fprintf(device.connectionHandle,':ABORt');

            %# clear Trigger events
            fprintf(device.connectionHandle,':TRIGger:CLEar');
            
            err = device.setOutputState(0);
        end
        
        function err = abortAll(device)
            if ~device.connected
                err = 1;
                errordlg(sprintf(getErrorMessage('deviceNotConnected'),device.defaultID))
                return
            end
            device.abortAllMeasurements = 1;
            fprintf(device.connectionHandle,':ABORt');

            %# clear Trigger events
            fprintf(device.connectionHandle,':TRIGger:CLEar');
            
            err = device.setOutputState(0);
        end
        
        function err = goIdle(device)
            if ~device.connected
                err = 1;
                errordlg(sprintf(getErrorMessage('deviceNotConnected'),device.defaultID))
                return
            end
            device.abortMeasurement = 0;
            device.abortAllMeasurements = 0;
            fprintf(device.connectionHandle,':ABORt');

            %# clear Trigger events
            fprintf(device.connectionHandle,':TRIGger:CLEar');
        end
        
        %# prepare settings for single point measurement
        function err = setPointV(device,sourceV,delay,varargin)
            input = inputParser;
            addRequired(input,'device')
            addRequired(input,'sourceV',validationFcn('keithleySetV',device.functionName));
            addRequired(input,'delay',validationFcn('keithleyDelay',device.functionName));
            addOptional(input,'integrationRate',device.intRate,validationFcn('keithleyIntegrationRate',device.functionName));
            parse(input,device,sourceV,delay,varargin{:})

            if ~device.connected
                err = 1;
                errordlg(sprintf(getErrorMessage('deviceNotConnected'),device.defaultID))
                return
            end

            %# set voltage as source
            err = setSource_Keithley(device.connectionHandle, 'V');
            if err
                errordlg(sprintf(getErrorMessage('keithleySetSourceV'),device.functionName))
                return
            end

            %# set point parameter as source voltage and delay
            err = device.updatePointV(input.Results.sourceV,input.Results.delay);
            if err
                return
            end

            %# set sense function (device, mode [I,V,R], int_rate, prot_lvl, range_auto, range)
            err = setSense_Keithley(device.connectionHandle, 'I', 'integrationRate',input.Results.integrationRate);
            if err
                errordlg(sprintf(getErrorMessage('keithleySetSourceV'),device.functionName))
                return
            end
            
            fprintf(device.connectionHandle,':FORM:ELEM:SENS VOLT,CURR,TIME'); % Specify data elements (VOLTage, CURRent,RESistance, TIME, and STATus).

            if ~device.outputState
                %# activate output if not already active
                err = toggleOutput_Keithley(device.connectionHandle, 'ON');
                if err
                    return
                end
                device.outputState = 1;
            end
        end

        function err = updatePointV(device,sourceV,delay,varargin)            
            input = inputParser;
            addRequired(input,'device')
            addRequired(input,'sourceV',validationFcn('keithleySetV',device.functionName));
            addRequired(input,'delay',validationFcn('keithleyDelay',device.functionName));
            addParameter(input,'mode','V',validationFcn('keithleyMode',device.functionName));
            parse(input,device,sourceV,delay,varargin{:})

            if ~device.connected
                err = 1;
                errordlg(sprintf(getErrorMessage('deviceNotConnected'),device.defaultID))
                return
            end

            %# set sweep mode to single point
            err = single_Keithley(device.connectionHandle, input.Results.mode, input.Results.sourceV);
            if err
                return
            end

            %# set delay between each measurement point
            err = setDelay_Keithley(device.connectionHandle, 'manual', input.Results.delay);
            if err
                return
            end
        end

        %# measure function single point
        function [outputData,err] = measurePointV(device)
            input = inputParser;
            addRequired(input,'device')
            parse(input,device)
            
            %# initialize default values
            outputData = struct();

            if ~device.connected
                err = 1;
                errordlg(sprintf(getErrorMessage('deviceNotConnected'),device.defaultID))
                return
            elseif ~device.outputState
                %# activate output if not already active
                err = toggleOutput_Keithley(device.connectionHandle, 'ON');
                if err
                    return
                end
                device.outputState = 1;
            end

            %# read measured values
            fprintf(device.connectionHandle,':READ?');

            %# extract double from scanned string
            numStr = fscanf(device.connectionHandle,'%c',42);
            nums = str2double(strsplit(numStr(1:end-1),','));

            %# assign measured values to variables
            outputData.voltage=nums(1);
            outputData.current=nums(2);
            outputData.time = nums(3);
            
            fprintf(device.connectionHandle,':ABORt');
            err = 0;
        end
        
        function err = setSweepV(device,start,stop,step,delay,varargin)
            input = inputParser;
            addRequired(input,'device')
            addRequired(input,'start',validationFcn('keithleySetV',device.functionName));
            addRequired(input,'stop',validationFcn('keithleySetV',device.functionName));
            addRequired(input,'step',validationFcn('keithleySetV',device.functionName));
            addRequired(input,'delay',validationFcn('keithleyDelay',device.functionName));
            addOptional(input,'integrationRate',device.intRate,validationFcn('keithleyIntegrationRate',device.functionName));
            addParameter(input,'spacing',device.spacing,validationFcn('keithleySpacing',device.functionName));
            parse(input,device,start,stop,step,delay,varargin{:})

            if ~device.connected
                err = 1;
                errordlg(sprintf(getErrorMessage('deviceNotConnected'),device.defaultID))
                return
            end

            %# set voltage as source
            err = setSource_Keithley(device.connectionHandle, 'V');
            if err
                errordlg(sprintf(getErrorMessage('keithleySetSourceV'),device.functionName))
                return
            end

            err = device.updateSweepV(input.Results.start,input.Results.stop,input.Results.step,input.Results.delay,input.Results.integrationRate,'spacing',input.Results.spacing);
            if err
                return
            end

            %# select elmements to sense (VOLTage, CURRent,RESistance, TIME, and STATus)
            fprintf(device.connectionHandle,':FORM:ELEM:SENS VOLT,CURR,TIME');

            if ~device.outputState
                %# activate output if not already active
                err = toggleOutput_Keithley(device.connectionHandle, 'ON');
                if err
                    return
                end
                device.outputState = 1;
            end
        end

        function err = updateSweepV(device,start,stop,step,delay,varargin)
            input = inputParser;
            addRequired(input,'device')
            addRequired(input,'start',validationFcn('keithleySetV',device.functionName));
            addRequired(input,'stop',validationFcn('keithleySetV',device.functionName));
            addRequired(input,'step',validationFcn('keithleySetStepV',device.functionName));
            addRequired(input,'delay',validationFcn('keithleyDelay',device.functionName));
            addOptional(input,'integrationRate',device.intRate,validationFcn('keithleyIntegrationRate',device.functionName));
            addParameter(input,'spacing',device.spacing,validationFcn('keithleySpacing',device.functionName));
            parse(input,device,start,stop,step,delay,varargin{:})

            if ~device.connected
                err = 1;
                errordlg(sprintf(getErrorMessage('deviceNotConnected'),device.defaultID))
                return
            end
            
            fprintf(device.connectionHandle,':ABORt');

            %# set sweep with given values for start, stop, step, spacing ('LIN', and 'LOG')
            err = sweep_Keithley(device.connectionHandle, 'V', input.Results.start, input.Results.stop, input.Results.step,'spacing',input.Results.spacing);
            if err
                return
            end

            %# set delay between each measurement point
            err = setDelay_Keithley(device.connectionHandle, 'manual', input.Results.delay);
            if err
                return
            end

            %# set sense function (device, mode [I,V,R], int_rate, prot_lvl, range_auto, range)
            err = setSense_Keithley(device.connectionHandle, 'I', 'integrationRate',input.Results.integrationRate);
            if err
                return
            end
        end

        %# measure function sweep
        function [outputData,err] = measureSweepV(device,varargin)
            input = inputParser;
            addRequired(input,'device')
            addParameter(input,'plotHandle',0,@(x) (isnumeric(x) && x==0) || isgraphics(x,'axes') || (isstruct(x) && isfield(x,'update')));
            parse(input,device,varargin{:});
            
            ax = input.Results.plotHandle;
            
            %# initialize default values
            outputData = struct();
            outputData.voltage = 0;
            outputData.current = 0;
            outputData.time    = 0;
            if device.abortMeasurement
                err = 88;
                return
            elseif device.abortAllMeasurements
                err = 99;
                return
            end

            if ~device.connected
                err = 1;
                errordlg(sprintf(getErrorMessage('deviceNotConnected'),device.defaultID))
                return
            elseif ~device.outputState
                %# activate output if not already active
                err = toggleOutput_Keithley(device.connectionHandle, 'ON');
                if err
                    return
                end
                device.outputState = 1;
            end

            %# preallocate space for results (Keithley stores internally up to 2500 points)
            voltage = zeros(2500,1);
            current = zeros(2500,1);
            time = zeros(2500,1);

            %# read measured values
            fprintf(device.connectionHandle,':READ?');
            
            n1 = 1;
            endReached = 0;
            %# extract measured values from string while measuring and update plot
            while ~device.abortMeasurement && ~device.abortAllMeasurements && ~endReached && n1<=2500
                try
                    %# read 3 values á 13 digits + comma
                    tmp = fscanf(device.connectionHandle,'%c',42);
                    splitted = strsplit(tmp,',');
                catch eee
                    disp(eee.message);
                    break;
                end

                %# stop reading if end of transmission is reached
                if isempty(tmp)
                    break;
                elseif isspace(tmp(end))
                    nums = str2double(splitted(1:end));
                    endReached = 1;
                else
                    nums = str2double(splitted(1:end-1));
                end

                voltage(n1) = nums(1);
                current(n1) = nums(2);
                time(n1)    = nums(3);

                if isgraphics(ax,'axes')
                    plot(ax,voltage(1:n1),current(1:n1))
                    xlabel(ax,'Voltage (V)')
                    ylabel(ax,'Current (A)')
                elseif isstruct(ax) && isfield(ax,'update')
                    ax.update(voltage(1:n1),current(1:n1),'xlabel','Voltage (V)','ylabel','Current (A)')
                end
                drawnow
                n1 = n1+1;
            end

            outputData.voltage = voltage(1:max(n1-1,1));
            outputData.current = current(1:max(n1-1,1));
            outputData.time    = time(1:max(n1-1,1));

            %# check if scan was aborted by user and adjust status
            if device.abortMeasurement
                device.setOutputState(0);
                device.abortMeasurement = 0;
                err = 88;
                return
            elseif device.abortAllMeasurements
                device.setOutputState(0);
                device.abortAllMeasurements = 0;
                err = 99;
                return
            else
                device.goIdle();
                err = 0;
                return
            end
        end
        
        %# generate prepuls
        function err = prebias(device,prepulsV,duration,delay)
            input = inputParser;
            addRequired(input,'device')
            addRequired(input,'prepulsV',validationFcn('keithleySetV',device.functionName));
            addRequired(input,'duration',validationFcn('keithleyDuration',device.functionName));
            addRequired(input,'delay',validationFcn('keithleyDelay',device.functionName));
            parse(input,device,prepulsV,duration,delay)

            if ~device.connected
                err = 1;
                errordlg(sprintf(getErrorMessage('deviceNotConnected'),device.defaultID))
                return
            end
            
            err = device.setPointV(input.Results.prepulsV,input.Results.delay);
            if err
                return
            end
            
            pause(input.Results.duration);
        end
        
        %# measureSweepV with single prepuls
        function [outputData,err] = measureSweepVPP(device,start,stop,step,delay,varargin)
            input = inputParser;
            addRequired(input,'device')
            addRequired(input,'start',validationFcn('keithleySetV',device.functionName));
            addRequired(input,'stop',validationFcn('keithleySetV',device.functionName));
            addRequired(input,'step',validationFcn('keithleySetStepV',device.functionName));
            addRequired(input,'delay',validationFcn('keithleyDelay',device.functionName));
            addOptional(input,'integrationRate',device.intRate,validationFcn('keithleyIntegrationRate',device.functionName));
            addParameter(input,'spacing',device.spacing,validationFcn('keithleySpacing',device.functionName));
            addParameter(input,'plotHandle',0,@(x) (isnumeric(x) && x==0) || isgraphics(x,'axes') || (isstruct(x) && isfield(x,'update')));
            addParameter(input,'prepulsV',0,validationFcn('keithleySetV',device.functionName));
            addParameter(input,'prepulsDuration',0,validationFcn('keithleyDelay',device.functionName));
            addParameter(input,'prepulsDelay',0,validationFcn('keithleyDelay',device.functionName));
            parse(input,device,start,stop,step,delay,varargin{:})
            
            outputData = struct();

            if ~device.connected
                err = 1;
                errordlg(sprintf(getErrorMessage('deviceNotConnected'),device.defaultID))
                return
            end
            
            err = device.prebias(input.Results.prepulsV,input.Results.prepulsDuration,input.Results.prepulsDelay);
            if err
                return
            end
            
            err = device.setSweepV(input.Results.start,input.Results.stop,input.Results.step,input.Results.delay,input.Results.integrationRate);
            if err
                return
            end
            
            [outputSweep,err] = device.measureSweepV('plotHandle',input.Results.plotHandle);
            device.setOutputState(0);
            if err
                return
            end
            
            outputData = outputSweep;
        end
        
        function [outputData,err] = measureCycle(device,vmpp,voc,step,delay,varargin)
            input = inputParser;
            addRequired(input,'device')
            addRequired(input,'vmpp',validationFcn('keithleySetV',device.functionName));
            addRequired(input,'voc',validationFcn('keithleySetV',device.functionName));
            addRequired(input,'step',validationFcn('keithleySetStepV',device.functionName));
            addRequired(input,'delay',validationFcn('keithleyDelay',device.functionName));
            addOptional(input,'integrationRate',device.intRate,validationFcn('keithleyIntegrationRate',device.functionName));
            addParameter(input,'plotHandle',0,@(x) (isnumeric(x) && x==0) || isgraphics(x,'axes') || (isstruct(x) && isfield(x,'update')));
            parse(input,device,vmpp,voc,step,delay,varargin{:})
            
            ax = input.Results.plotHandle;

            outputData = struct();
            outputData.voltage = 0;
            outputData.current = 0;
            outputData.time    = 0;
            if device.abortMeasurement
                err = 88;
                return
            elseif device.abortAllMeasurements
                err = 99;
                return
            end
            
            if ~device.connected
                err = 1;
                errordlg(sprintf(getErrorMessage('deviceNotConnected'),device.defaultID))
                return
            end

            vmpp = input.Results.vmpp;
            voc = input.Results.voc;
            step = input.Results.step;

            %# MPP->JSC->VOC->JSC
            volt = [vmpp:-step:0, 0:step:voc,voc:-step:0];

            %# set voltage as source
            err = setSource_Keithley(device.connectionHandle, 'V');
            if err
                errordlg(sprintf(getErrorMessage('keithleySetSourceV'),device.functionName))
                return
            end

            %# set list as sweep
            err = list_Keithley(device.connectionHandle, 'V', volt);
            if err
                return
            end

            %# set delay between each measurement point
            err = setDelay_Keithley(device.connectionHandle, 'manual', input.Results.delay);
            if err
                return
            end

            %# set sense function (device, mode [I,V,R], int_rate, prot_lvl, range_auto, range)
            err = setSense_Keithley(device.connectionHandle, 'I', 'integrationRate',input.Results.integrationRate);
            if err
                log.update(['Could not set integrationRate ',num2str(input.Results.integrationRate),' in cycle!'])
                return
            end

            fprintf(device.connectionHandle,':FORM:ELEM:SENS VOLT,CURR,TIME');

%             %# preallocate space for results
%             voltage = zeros(length(volt),1);
%             current = zeros(length(volt),1);
%             time    = zeros(length(volt),1);
            
            if ~device.outputState
                %# activate output if not already active
                err = toggleOutput_Keithley(device.connectionHandle, 'ON');
                if err
                    return
                end
                device.outputState = 1;
            end

            %# request data
            fprintf(device.connectionHandle,':READ?');

            tmp = '';
            endReached = 0;
            %# extract measured values from string while measuring and update plot
            while ~device.abortMeasurement && ~device.abortAllMeasurements && ~endReached
                try
                    tmp = [tmp,fscanf(device.connectionHandle,'%c',84)];
                    splitted = strsplit(tmp,',');
                catch eee
                    disp(eee.message);
                    break;
                end

                %# stop reading if end of transmission is reached
                if isempty(tmp)
                    break;
                elseif isspace(tmp(end))
                    nums = str2double(splitted(1:end));
                    endReached = 1;
                else
                    nums = str2double(splitted(1:end-1));
                end

                voltage = nums(1:3:end-2);
                current = nums(2:3:end-1);
                time = nums(3:3:end);

                if isgraphics(ax,'axes')
                    plot(ax,voltage,current)
                    xlabel(ax,'Voltage (V)')
                    ylabel(ax,'Current (A)')
                    drawnow
                elseif isstruct(ax) && isfield(ax,'update')
                    ax.update(voltage,current,'xlabel','Voltage (V)','ylabel','Current (A)')
                end
            end
            device.setOutputState(0);
            
            outputData.voltage = voltage';
            outputData.current = current';
            outputData.time = time';

            %# check if scan was aborted by user and adjust status
            if device.abortMeasurement
                device.setOutputState(0);
                device.abortMeasurement = 0;
                err = 88;
                return
            elseif device.abortAllMeasurements
                device.setOutputState(0);
                device.abortAllMeasurements = 0;
                err = 99;
                return
            else
                device.goIdle();
                err = 0;
                return
            end
        end
        
        function err = setTimeScan(device,sourceV,delay,varargin)
            input = inputParser;
            addRequired(input,'device')
            addRequired(input,'sourceV',validationFcn('keithleySetV',device.functionName));
            addRequired(input,'delay',validationFcn('keithleyDelay',device.functionName));
            addOptional(input,'integrationRate',device.intRate,validationFcn('keithleyIntegrationRate',device.functionName));
            addParameter(input,'mode','V',validationFcn('keithleyMode',device.functionName));
            parse(input,device,sourceV,delay,varargin{:})
            
            mode = input.Results.mode;
            
            if ~device.connected
                err = 1;
                errordlg(sprintf(getErrorMessage('deviceNotConnected'),device.defaultID))
                return
            end
            
            %# clear Trigger events
            fprintf(device.connectionHandle,':TRIGger:CLEar');
            
            %# set voltage as source
            err = setSource_Keithley(device.connectionHandle, mode);
            if err
                errordlg(sprintf(getErrorMessage('keithleySetSourceV'),device.functionName))
                return
            end
            
            err = device.updateTimeScan(input.Results.sourceV,input.Results.delay,input.Results.integrationRate,'resetTime',1,'mode',mode);
            if err
                return
            end
            
            fprintf(device.connectionHandle,':FORM:ELEM:SENS VOLT,CURR,TIME');
            
            %# Specify trigger count (1 to 2500).
            fprintf(device.connectionHandle,':TRIG:COUN 2500');
            
            toggleAutoclear_Keithley(device.connectionHandle, 'OFF');
            
            if ~device.outputState
                %# activate output if not already active
                err = toggleOutput_Keithley(device.connectionHandle, 'ON');
                if err
                    return
                end
                device.outputState = 1;
            end
        end
        
        function err = updateTimeScan(device,sourceV,delay,varargin)
            input = inputParser;
            addRequired(input,'device')
            addRequired(input,'sourceV',validationFcn('keithleySetV',device.functionName));
            addRequired(input,'delay',validationFcn('keithleyDelay',device.functionName));
            addOptional(input,'integrationRate',device.intRate,validationFcn('keithleyIntegrationRate',device.functionName));
            addParameter(input,'resetTime',0,validationFcn('boolean',device.functionName));
            addParameter(input,'mode','V',validationFcn('keithleyMode',device.functionName));
            parse(input,device,sourceV,delay,varargin{:})
            
            mode = input.Results.mode;
                modeSense = con_a_b(strcmp(mode,'V'),'I','V');
            
            if ~device.connected
                err = 1;
                errordlg(sprintf(getErrorMessage('deviceNotConnected'),device.defaultID))
                return
            end
            
            err = device.updatePointV(input.Results.sourceV,input.Results.delay,'mode',mode);
            if err
                return
            end
            
            err = setSense_Keithley(device.connectionHandle, modeSense, 'integrationRate',input.Results.integrationRate);
            if err
                return
            end
            
            if input.Results.resetTime
                fprintf(device.connectionHandle,':SYST:TIME:RES');
            end
        end
        
        function [outputData,err] = measureTimeScan(device,duration,varargin)
            input = inputParser;
            addRequired(input,'device')
            addRequired(input,'duration',validationFcn('keithleyDuration',device.functionName));
            addParameter(input,'hold',0,validationFcn('boolean',device.functionName));
            addParameter(input,'plotHandle',0,@(x) (isnumeric(x) && x==0) || isgraphics(x,'axes') || (isstruct(x) && isfield(x,'update')));
            addParameter(input,'temperatureController',[]);
            addParameter(input,'mode','V',validationFcn('keithleyMode',device.functionName));
            parse(input,device,duration,varargin{:})
            
            mode = input.Results.mode;
                modeYLabel = con_a_b(strcmp(mode,'V'),'Current (A)','Voltage (V)');
            
            ax = input.Results.plotHandle;
            tC = input.Results.temperatureController;
            
            outputData = struct();
            outputData.voltage = 0;
            outputData.current = 0;
            outputData.time    = 0;
            if device.abortMeasurement
                err = 88;
                return
            elseif device.abortAllMeasurements
                err = 99;
                return
            end
            
            if ~device.connected
                err = 1;
                errordlg(sprintf(getErrorMessage('deviceNotConnected'),device.defaultID))
                return
            elseif ~device.outputState
                %# activate output if not already active
                err = toggleOutput_Keithley(device.connectionHandle, 'ON');
                if err
                    return
                end
                device.outputState = 1;
            end
            
            %# preallocate memory for results
            endReached = 0;
            current = zeros(2500,1);
            voltage = zeros(2500,1);
            time = zeros(2500,1);
            if ~isempty(tC)
                temperature = zeros(2500,1);
                tempFactor = tC.startTemp>tC.endTemp;
            end
            
            %# clear Trigger events
            fprintf(device.connectionHandle,':TRIGger:CLEar');
            fprintf(device.connectionHandle,':TRIG:COUN 2500');
            
            t0 = query(device.connectionHandle,':SYST:TIME?');
            if isempty(t0)
                fprintf(device.connectionHandle,':ABORt');
                device.setOutputState(0);
                err = -2;
                return
            else
                t0 = str2double(t0);
            end
            
            fprintf(device.connectionHandle,':READ?');
            tmp = '';
            a = 0;
            divisor = 2000;
            divisorStep = divisor;
            %# extract measured values from string while measuring and update plot
            while ~device.abortMeasurement && ~device.abortAllMeasurements && ~endReached && a<duration
                if ~device.getOutputState()
                    outputData.voltage = 0;
                    outputData.current = 0;
                    outputData.time    = 0;
                    err = 88;
                    return;
                end
                try
                    tmp = [tmp,fscanf(device.connectionHandle,'%c',84)];
                    splitted = strsplit(tmp,',');
                catch eee
                    disp(eee.message);
%                     device.abortAllMeasurements = 1;
%                     break;
                end
                
                %# stop reading if end of transmission is reached
                if isempty(tmp)
                    break;
                elseif isspace(tmp(end))
                    nums = str2double(splitted(1:end));
                    endReached = 1;
                else
                    nums = str2double(splitted(1:end-1));
                end

                voltage = nums(1:3:end-2);
                current = nums(2:3:end-1);
                time = nums(3:3:end);
                a = time(end)-time(1);
                if ~isempty(tC)
                    b = length(nonzeros(time));
                    c = length(nonzeros(temperature));
                    outputTemp = tC.device.getTemp();
                    temperature(c+1:b) = repmat(outputTemp.temperature,size(c+1:b));
                    if abs((time(end)-time(1))-tC.delay)<1 && tC.rampActive
                        tC.device.startRamp(tC.rate);
                        tC.device.setTemp(tC.endTemp);
                        disp('ramp started')
                        pause(2)
                    end
                    if con_a_b(tempFactor<0,outputTemp.temperature<tC.endTemp,outputTemp.temperature>tC.endTemp) && (duration-a)>tC.delay
                        duration = a+tC.delay;
                    end
                end
                
                if (length(voltage)/divisor)>1
                    length(voltage)
                    divisor = divisor+divisorStep;
                    fprintf(device.connectionHandle,':ABORt');
                    fprintf(device.connectionHandle,':TRIG:COUN 2500');
                    fprintf(device.connectionHandle,':READ?');
                end
                
                if isgraphics(ax,'axes')
                    if input.Results.hold
                        hold on
                    else
                        hold off
                    end
                    
                    plot(ax,time(1:ceil(length(time)/250):end),current(1:ceil(length(current)/250):end),'Color',ax.ColorOrder(1,:))
                    xlabel(ax,'Time (s)')
                    ylabel(ax,modeYLabel)
                    drawnow
                elseif isstruct(ax) && isfield(ax,'update')
                    ax.update(time(1:ceil(length(time)/250):end),current(1:ceil(length(current)/250):end),'xlabel','Time (s)','ylabel',modeYLabel,'hold',input.Results.hold)
                end
            end
            
            outputData.voltage = voltage';
            outputData.current = current';
            outputData.time = time';
            outputData.t0 = t0';
            if ~isempty(tC)
                outputData.temperature = temperature(1:length(time));
            end
            
            %# check if scan was aborted by user and adjust status
            if device.abortMeasurement
                device.abortMeasurement = 0;
                device.setOutputState(0);
                err = 88;
                return
            elseif device.abortAllMeasurements
                device.abortAllMeasurements = 0;
                device.setOutputState(0);
                err = 99;
                return
            else
                device.goIdle();
                device.setOutputState(0);
                err = 0;
                return
            end
        end
        
        function [outputData,err] = measureSteadyState(device,sourceV,duration,varargin)
            input = inputParser;
            addRequired(input,'device')
            addRequired(input,'sourceV',validationFcn('keithleySetV',device.functionName));
            addRequired(input,'duration',validationFcn('keithleyDuration',device.functionName));
            addOptional(input,'delay',0,validationFcn('keithleyDelay',device.functionName));
            addOptional(input,'integrationRate',min(device.intRate*2,10),validationFcn('keithleyIntegrationRate',device.functionName));
            addParameter(input,'plotHandle',0,@(x) (isnumeric(x) && x==0) || isgraphics(x,'axes') || (isstruct(x) && isfield(x,'update')));
            addParameter(input,'hold',0,validationFcn('boolean',device.functionName));
            addParameter(input,'track','mpp',@(x) any(validatestring(lower(x),{'mpp','voc','jsc'})));
            addParameter(input,'temperatureController',[]);
            parse(input,device,sourceV,duration,varargin{:})
            
            ax = input.Results.plotHandle;
            tC = input.Results.temperatureController;
            
            outputData = struct();
            outputData.power = 0;
            outputData.voltage = 0;
            outputData.current = 0;
            outputData.time    = 0;
            if device.abortMeasurement
                err = 88;
                return
            elseif device.abortAllMeasurements
                err = 99;
                return
            end
            
            if ~device.connected
                err = 1;
                errordlg(sprintf(getErrorMessage('deviceNotConnected'),device.defaultID))
                return
            end
            err = 0;

            if strcmpi(input.Results.track,'jsc')
                err = device.setTimeScan(0,input.Results.delay,input.Results.integrationRate);
                if err
                    return
                end
                
                [outputData,err] = device.measureTimeScan(duration,'plotHandle',ax,'hold',input.Results.hold,'temperatureController',tC);
                return
            elseif strcmpi(input.Results.track,'voc')
                err = device.setTimeScan(0,input.Results.delay,input.Results.integrationRate,'mode','I');
                if err
                    return
                end
                
                [outputData,err] = device.measureTimeScan(duration,'plotHandle',ax,'hold',input.Results.hold,'temperatureController',tC,'mode','I');
                return
            end
            
            %first data
            n1=1;
            power  = zeros(100000,1);
            voltage = zeros(100000,1);
            current = zeros(100000,1);
            time = zeros(100000,1);
            if ~isempty(tC)
                temperature = zeros(10000,1);
                tempFactor = tC.startTemp>tC.endTemp;
            end
            
            currentVolt = sourceV;
            step = 0.02;
            minstep = 0.001;
            maxstep = 0.05;
            
            %# reset timer in Keithley
            fprintf(device.connectionHandle,':SYST:TIME:RES');
            
            a = 0;
            while a<duration && ~device.abortMeasurement && ~device.abortAllMeasurements
                err = device.setSweepV(currentVolt-2*step,currentVolt+2*step,step,input.Results.delay,input.Results.integrationRate);
                if err
                    break;
                end
                [outputSweep,err] = device.measureSweepV();
                if err == 88 || err == 99
                    break;
                end
                
                %# calculate power of measurement and find max current powerpoint and index for next voltage
                sweepPower = abs(outputSweep.current.*outputSweep.voltage);
                switch input.Results.track
                    case 'mpp'
                        [power(n1),index] = max(sweepPower);
                    	current(n1) = outputSweep.current(index);
                    case 'voc'
                        [current(n1),index] = min(abs(outputSweep.current));
                        power(n1) = sweepPower(index);
                end
                voltage(n1) = outputSweep.voltage(index);
                time(n1) = outputSweep.time(index);
                a = time(n1)-time(1);
                
                %# temperature controll
                if ~isempty(tC)
                    outputTemp = tC.device.getTemp();
                    temperature(n1) = outputTemp.temperature;
                    if abs((time(n1)-time(1))-tC.delay)<1 && tC.rampActive
                        tC.device.startRamp(tC.rate);
                        tC.device.setTemp(tC.endTemp);
                        disp('ramp started')
                    end
                    if con_a_b(tempFactor<0,outputTemp.temperature<tC.endTemp,outputTemp.temperature>tC.endTemp) && (duration-a)>tC.delay
                        duration = a+tC.delay;
                    end
                end
                
                %# new center voltage for next loop
                currentVolt = voltage(n1); 
                
                %# abort measurement to not destroy solar cell
                if abs(currentVolt) > 1.2 
                    err = 77;
                    break;
                end
                
                %# adjust scan range
                if index == 1 || index == 5
                    step = min(1.5*step,maxstep);
                else
                    step = max(round(step/4,3),minstep);
                end
                
                if isgraphics(ax,'axes')
                    if input.Results.hold
                        hold on
                    else
                        hold off
                    end
                    
                    switch input.Results.track
                        case 'mpp'
                            plot(ax,time(1:ceil(n1/250):n1),power(1:ceil(n1/250):n1),'Color',ax.ColorOrder(2,:))
                            xlabel(ax,'Time (s)')
                            ylabel(ax,'Maximum Power (mW)')
                        case 'voc'
                            plot(ax,time(1:ceil(n1/250):n1),voltage(1:ceil(n1/250):n1),'Color',ax.ColorOrder(3,:))
                            xlabel(ax,'Time (s)')
                            ylabel(ax,'V_{OC} (V)')
                    end
                    drawnow
                elseif isstruct(ax) && isfield(ax,'update')
                    switch input.Results.track
                        case 'mpp'
                            ax.update(time(1:ceil(n1/250):n1),power(1:ceil(n1/250):n1),'xlabel','Time (s)','ylabel','Maximum Power (mW)','hold',input.Results.hold)
                        case 'voc'
                            ax.update(time(1:ceil(n1/250):n1),voltage(1:ceil(n1/250):n1),'xlabel','Time (s)','ylabel','V_{OC} (V)','hold',input.Results.hold)
                    end
                    
                end                
                n1 = n1 + 1;
            end
            device.setOutputState(0);
            
            outputData.power  = abs(power(1:max(n1-1,1)));
            outputData.voltage = abs(voltage(1:max(n1-1,1)));
            outputData.current = abs(current(1:max(n1-1,1)));
            outputData.time = time(1:max(n1-1,1));
            if ~isempty(tC)
                outputData.temperature = temperature(1:max(n1-1,1));
            end
        end
        
        function [outputData,err] = measureTimePointV(device,sourceV,duration,delay,varargin)
            input = inputParser;
            addRequired(input,'device')
            addRequired(input,'sourceV',validationFcn('keithleySetMultV',device.functionName));
            addRequired(input,'duration',validationFcn('keithleyDelayMult',device.functionName));
            addRequired(input,'delay',validationFcn('keithleyDelay',device.functionName));
            addOptional(input,'integrationRate',device.intRate,validationFcn('keithleyIntegrationRate',device.functionName));
            addParameter(input,'lightControl',[]);
            addParameter(input,'plotHandle',0,@(x) (isnumeric(x) && x==0) || isgraphics(x,'axes') || (isstruct(x) && isfield(x,'update')));
            parse(input,device,sourceV,duration,delay,varargin{:})
            
            lC = input.Results.lightControl;
            if isfield(lC,'device')
                lC.state = lC.customLightMeasurement(lC.cLightList{lC.n},1);
                lC.duration = lC.customLightMeasurement(lC.cLightList{lC.n},2);
                lC.device.newList(lC.duration,lC.state); %Light control unit (shutter) should have implemented a function list, which accepts state and duration as numeric array
            end
            
            ax = input.Results.plotHandle;
            
            outputData = struct();
            outputData.voltage = 0;
            outputData.current = 0;
            outputData.time    = 0;
            if device.abortMeasurement
                err = 88;
                return
            elseif device.abortAllMeasurements
                err = 99;
                return
            end
            
            if ~device.connected
                err = 1;
                errordlg(sprintf(getErrorMessage('deviceNotConnected'),device.defaultID))
                return
            end
            err = device.setTimeScan(input.Results.sourceV(1),input.Results.delay,input.Results.integrationRate);
            if err
                return
            end

            if isfield(lC,'device')
                % if light control is activated, start now
                err = lC.device.start();
%                 if err
%                     return
%                 end
            end
            [outputData,err] = device.measureTimeScan(input.Results.duration(1),'plotHandle',ax);
            if err
                return
            end
            
            for n1 = 2:length(input.Results.sourceV)
                if input.Results.duration(n1)>0
                    err = device.updateTimeScan(input.Results.sourceV(n1),input.Results.delay,input.Results.integrationRate);
                    if err
                        return
                    end
                    
                    [outputDataTemp,err] = device.measureTimeScan(input.Results.duration(n1),'plotHandle',ax,'hold',1);
                    if err
                        return
                    end
                    
                    outputData.voltage = [outputData.voltage;outputDataTemp.voltage];
                    outputData.current = [outputData.current;outputDataTemp.current];
                    outputData.time = [outputData.time;outputDataTemp.time];
                    outputData.t0 = [outputData.t0;outputDataTemp.t0];
                end
            end
            device.setOutputState(0);
            if isfield(lC,'device')
                err = lC.device.close();
                err = lC.device.clear();
%                 if err
%                     return
%                 end
            end
            outputData.time = outputData.time-outputData.time(1);
            
            %# check if scan was aborted by user and adjust status
            if device.abortMeasurement
                device.setOutputState(0);
                device.abortMeasurement = 0;
                err = 88;
                return
            elseif device.abortAllMeasurements
                device.setOutputState(0);
                device.abortAllMeasurements = 0;
                err = 99;
                return
            else
                err = 0;
                return
            end
        end
        
        function [outputData,err] = measureTimeSweepV(device,start,stop,step,duration,delay,varargin)
            input = inputParser;
            addRequired(input,'device')
            addRequired(input,'start',validationFcn('keithleySetV',device.functionName));
            addRequired(input,'stop',validationFcn('keithleySetV',device.functionName));
            addRequired(input,'step',validationFcn('keithleySetStepV',device.functionName));
            addRequired(input,'duration',validationFcn('keithleyDuration',device.functionName));
            addRequired(input,'delay',validationFcn('keithleyDelay',device.functionName));
            addOptional(input,'integrationRate',min(device.intRate*2,10),validationFcn('keithleyIntegrationRate',device.functionName));
            addParameter(input,'plotHandle',0,@(x) (isnumeric(x) && x==0) || isgraphics(x,'axes') || (isstruct(x) && isfield(x,'update')));
            parse(input,device,start,stop,step,duration,delay,varargin{:})
            
            ax = input.Results.plotHandle;
            
            outputData = struct();
            outputData.voltage = 0;
            outputData.current = 0;
            outputData.time    = 0;
            if device.abortMeasurement
                err = 88;
                return
            elseif device.abortAllMeasurements
                err = 99;
                return
            end
            
            if ~device.connected
                err = 1;
                errordlg(sprintf(getErrorMessage('deviceNotConnected'),device.defaultID))
                return
            end
            
            start = input.Results.start;
            stop = input.Results.stop;
            step = input.Results.step;
            duration = input.Results.duration;
            delay = input.Results.delay;
            integrationRate = input.Results.integrationRate;
            
            err = device.setTimeScan(start,delay,integrationRate);
            if err
                return
            end
            
            for sourceV=start:step:stop
                sourceV
                err = device.updateTimeScan(sourceV,delay,integrationRate);
                if err
                    return
                end
                
                if start==sourceV
                    [outputData,err] = device.measureTimeScan(duration,'plotHandle',ax);
                    t0 = outputData.time(1);
                else
                    [outputDataTemp,err] = device.measureTimeScan(duration,'plotHandle',ax,'hold',1);
                    outputData.voltage = [outputData.voltage;outputDataTemp.voltage];
                    outputData.current = [outputData.current;outputDataTemp.current];
                    outputData.time = [outputData.time;outputDataTemp.time-t0];
                end
                
                if err == 88 || err == 99
                    return
                end
            end
            device.setOutputState(0);
        end
    end
end