%% ------------------------- The Signal generator 100 MHz----------------------- %%
% Connect 
ip = 'USB0::0x1AB1::0x0647::DG5P272700184::0::INSTR'; 
gen = DG5000Pro(ip);
gen.connect();

%% Channel 1
gen.setWaveform(1, 'SINE');
gen.setFrequency(1, 5e6);       
gen.setAmplitude(1, 10);         
gen.setPhase(1, 0);              
gen.setOffset(1, 0);             

gen.setBurstState(1, 'ON');      
gen.setBurstCycles(1, 10);        % cycle
gen.setBurstPeriod(1, 0.01);  
gen.setDelay(1,3.2e-6);
gen.setBurstSource(1, 'INT');    % 'BUS' or 'INT' 
gen.alignPhase();

%% Enable outputs
gen.outputOn(1);

%% Disable outputs
gen.outputOff(1);

%% xyz Motor initialization 
%% Y-Axis
ySerialNumber = '0021550514';  
yMotor = PIMotorController(ySerialNumber, '1');
yMotor.connect();
yMotor.setServo(true);
[minPosY, maxPosY, yRange] = yMotor.getTravelRange();
fprintf('Y-axis travel range: %.2f mm to %.2f mm\n', minPosY, maxPosY);
%% moving
movementY = 13.5;

if movementY >= 12 && movementY <= 15
    pos_y_start = minPosY + movementY;
    yMotor.moveAbs(pos_y_start);
else
    error('Y movement must be between 12 and 15.');
end

%% X-Axis
xSerialNumber = '0021550510';  
xMotor = PIMotorController(xSerialNumber, '1');
xMotor.connect();
xMotor.setServo(true);
[minPosX, maxPosX, xRange] = xMotor.getTravelRange();
fprintf('X-axis travel range: %.2f mm to %.2f mm\n', minPosX, maxPosX);
%% moving
movement = 11;   % Example value

if movement >= 10 && movement <= 13
    pos_x_start = minPosX + movement;
    xMotor.moveAbs(pos_x_start);
else
    error('Movement must be between 10 and 13.');
end
%% Z-Axis
zSerialNumber = '0021550513';  
zMotor = PIMotorController(zSerialNumber, '1');
zMotor.connect();
zMotor.setServo(true);
[minPos, maxPos, zRange] = zMotor.getTravelRange();
fprintf('Z-axis travel range: %.2f mm to %.2f mm\n', minPos, maxPos);
%% Move 
pos_z = minPos +13;
zMotor.moveAbs(pos_z);
%% Oscilloscope Initialization for HF MHz with RF switch
ipAddress = '10.48.7.251';
osc = T3DSO2502A(ipAddress);
osc.setInputBufferSize(2^22);   % Increase input buffer size to 4MB
osc.setTimeout(60);             % Set timeout to 60 seconds
osc.connect();

% Configure oscilloscope settings
% horizontal settings "time scale"
timeScale = 10e-6; % time per division
numberDivisions = 10;
totalSpan = timeScale * numberDivisions; 
osc.setTimeScale(timeScale);
osc.setTimebaseDelay(-totalSpan/2);

% acquisition and triggering
osc.setImpedance(1,'FIFT')%50 Ohms
osc.setImpedance(2,'FIFT')%50 Ohms
%osc.setImpedance(3,'FIFT')%50 Ohms
% osc.setAcquisitionType('AVER'); %does not exist here
osc.setAcquisitionType('NORM');
osc.setTriggerType('EDGE');
osc.setTriggerLevel(75e-3);

% no averaging in this osc model
% avgCount = 1024;
% fprintf(osc.visaObj, sprintf(':ACQW:AVER:COUN %d', avgCount));

% vertical settings "Voltage scale"
osc.setVerticalScale(1, 1);
osc.setVerticalScale(2, 200e-3);
%osc.setVerticalScale(3, 1);
%osc.setFunctionVerticalScaleAve(2,200e-3)
osc.setOffset(1,0);
osc.setOffset(2,0);
osc.setOffset(3,0);
osc.setOffset(4,0);
%osc.setFunctionOffsetAve(2,0);
%pause(1);

% Confirm what the oscilloscope applied
Fs_actual = osc.getSampleRate();
fprintf('Oscilloscope sample rate set to: %.2f MSa/s\n', Fs_actual/1e6);

totalTime = timeScale * 10; % 10 divisions
adcMaxValue = 2^16;     % 16-bit ADC resolution

%% Define Frequency Sweep Parameters & Folders
freqStart = 1e6;     % 1 MHz
freqStop  = 15e6;    % 15 MHz
freqStep  = 1e6;     % 1 MHz step

freqList = freqStart : freqStep : freqStop;
numF = length(freqList);

% Move once to the fixed XY position 
xMotor.moveAbs(pos_x_start);
yMotor.moveAbs(pos_y_start);
pause(2);

dateFolder = datestr(now, 'yyyy-mm-dd');
subFolderName = 'freq_sweep_fixedXY';
outputFolder = fullfile(pwd, dateFolder, subFolderName);

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

%% Frequency sweep loop
allData = cell(1, numF);
allFreq = zeros(1, numF);
t = [];
for k = 1:numF
    currentF = freqList(k);
    gen.setFrequency(1, currentF);
    gen.alignPhase();
    
    osc.resetAveragingByOffset(2);
    pause(20);
    
    % Acquire signal
    [data, t] = acquire_single_trace(osc, adcMaxValue, Fs_actual, t);
    
    % Store
    allData{k} = data;
    allFreq(k) = currentF;
    
    fprintf('Freq point [%d/%d] saved: f=%.3f MHz\n', k, numF, currentF/1e6);
end
save(fullfile(outputFolder, 'freq_sweep_1to15MHz_fixedXY_10Cycles_x11mm_y13mm.mat'),'allData', 't', 'allFreq', '-v7.3');

%% return to the same position
initialX = pos_x_start;
initialY = pos_y_start;
xMotor.moveAbs(initialX);
yMotor.moveAbs(initialY);
fprintf('Returned to: X=%.3f, Y=%.3f\n', initialX, initialY);
%% Plot for test the data
k = 6;
tr = allData{k};
figure;
plot(t,tr)
title(sprintf('Trace at f = %.2f MHz', allFreq(k)/1e6));
xlabel('Time (s)'); ylabel('Amplitude');