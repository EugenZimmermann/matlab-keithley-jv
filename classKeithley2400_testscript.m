addpath('.\Common')
addpath(genpath('.\CommonDevice\Keithley'))

%# define pause time between commands for test
pTime = 1;

%# create Keithley2400 object with specified connection type and port
k = classKeithley2400_pub('connectionType','gpib','port',24);

%# reset device to initial state
k.reset()

%# connect to device (0 if OK, else if error)
k.connect()

pause(pTime)

%# disconnect to device (0 if OK, else if error)
k.disconnect()

pause(pTime)

%# connect to device (0 if OK, else if error)
k.connect()

pause(pTime)

%# get conenction status (1 if OK) and ID of device
[connectionStatus, ID] = k.getConnectionStatus()

pause(pTime)

%# activate Output
k.setOutputState(1)

pause(pTime)

%# ask for Output status
outputState = k.getOutputState()

pause(pTime)

%# deactivate Output without argument or with 0
k.setOutputState()

pause(pTime)
%%
%# set single point measurement setPointV(voltage,delay,integrationRate (optional))
k.setPointV(0.1,0)

pause(pTime)

%# measure single point measurePointV()
dataPointV1 = k.measurePointV()

pause(pTime)

%# update single point updatePointV(voltage,delay)
k.updatePointV(-0.1,1)

pause(pTime)

%# measure single point measurePointV()
dataPointV2 = k.measurePointV()

%# deactivate Output without argument or with 0
k.setOutputState()

pause(pTime)
%%
%# set sweep measurement setSweepV(startVoltage,stopVoltage,stepSize,delay,integrationRate (optional),spacing (parameter))
k.setSweepV(0,0.3,0.1,0)

pause(pTime)

%# measure sweep measureSweepV(plotHandle (optional))
dataSweepV1 = k.measureSweepV()

pause(pTime)

%# update sweep updateSweepV(startVoltage,stopVoltage,stepSize,delay,integrationRate (optional),spacing (parameter))
k.updateSweepV(0.3,0,-0.01,0)

pause(pTime)

%# measure sweep measureSweepV()
f.Sweep = figure('Position',[200,200,400,300]);
ax.Sweep = axes('parent',f.Sweep);
dataSweepV2 = k.measureSweepV('plotHandle',ax.Sweep)

%# deactivate Output without argument or with 0
k.setOutputState()

pause(pTime)
%%
%# set and measure sweep with prepuls measureSweepVPP(startVoltage,stopVoltage,stepSize,delay,...
%#                                                    integrationRate (optional),spacing (parameter),...
%#                                                    prepulsV (parameter),prepulsDuration (parameter),...
%#                                                    prepulsDelay (parameter),plotHandle (parammeter))
f.SweepPP = figure('Position',[200,200,400,300]);
ax.SweepPP = axes('parent',f.SweepPP);
dataSweepVPP = k.measureSweepVPP(0,0.3,0.01,0,'prepulsV',-0.1,'prepulsDuration',1,'prepulsDelay',0.1,'plotHandle',ax.SweepPP)

pause(pTime)
%%
%# set and measure cyclic sweep measureCycle(mppVoltage,vocVoltage,stepSize,delay,...
%#                                           integrationRate (optional),plotHandle (parammeter))
f.SweepCycle = figure('Position',[200,200,400,300]);
ax.SweepCycle = axes('parent',f.SweepCycle);
dataSweepCycle = k.measureCycle(0.2,0.35,0.01,0,'plotHandle',ax.SweepCycle)

pause(pTime)
%%
%# set and measure steady state tracking measureSteadyState(sourceV,duration,delay (optional), integrationRate (optional),...
%#                                                          plotHandle (parammeter), hold (parameter), track (parameter))
f.SteadyState = figure('Position',[200,200,400,300]);
ax.SteadyState = axes('parent',f.SteadyState);
dataSteadyStateMPP = k.measureSteadyState(0.2,5,'plotHandle',ax.SteadyState)

pause(pTime)

dataSteadyStateJSC = k.measureSteadyState(0.4,5,'plotHandle',ax.SteadyState,'hold',1,'track','jsc')

pause(pTime)

dataSteadyStateVOC = k.measureSteadyState(0.4,5,'plotHandle',ax.SteadyState,'hold',1,'track','voc')

pause(pTime)
%%
%# set timescan measurement setTimeScan(voltage,delay,integrationRate (optional))
k.setTimeScan(0.1,0)

pause(pTime)

%# measure timescan measureTimeScan(duration,plotHandle (parammeter),hold (parameter))
f.TimeScan = figure('Position',[200,200,400,300]);
ax.TimeScan = axes('parent',f.TimeScan);
dataTimeScan1 = k.measureTimeScan(10,'plotHandle',ax.TimeScan)

pause(pTime)

%# update single point updatePointV(voltage,delay,integrationRate (optional),resetTime (parameter))
k.updateTimeScan(-0.1,0,'resetTime',1)

pause(pTime)

%# measure timescan measureTimeScan(duration,plotHandle (parammeter),hold (parameter))
dataTimeScan2 = k.measureTimeScan(15,'plotHandle',ax.TimeScan,'hold',1)

%# deactivate Output without argument or with 0
k.setOutputState()

pause(pTime)
%%
%# set and measure timeresolved (multiple) voltage points measureTimePointV([voltage],[duration],delay,...
%#                                                                          integrationRate (optional),plotHandle (parammeter))
f.TimePointV = figure('Position',[200,200,400,300]);
ax.TimePointV = axes('parent',f.TimePointV);
dataTimePointV = k.measureTimePointV([0,0],[2,3],0,'plotHandle',ax.TimePointV)

pause(pTime)
%%
%# set and measure a timeresolved voltage sweep measureTimeSweepV(startVoltage,stopVoltage,stepSize,duration,delay,...
%#                                                                integrationRate (optional),plotHandle (parammeter))
f.TimeSweepV = figure('Position',[200,200,400,300]);
ax.TimeSweepV = axes('parent',f.TimeSweepV);
dataTimeSweepV = k.measureTimeSweepV(0.1,0.3,0.1,5,0,'plotHandle',ax.TimeSweepV)

pause(pTime)