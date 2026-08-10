%% ------------------------- The Signal generator 100 MHz----------------------- %%
% Connect 
ip = 'USB0::0x1AB1::0x0647::DG5P272700184::0::INSTR'; 
gen = DG5000Pro(ip);
gen.connect();

%% Channel 1
gen.setWaveform(1, 'SINE');
gen.setImpedance(1, 50); 
gen.setFrequency(1, 20e6);       
gen.setAmplitude(1, 10);         
gen.setPhase(1, 0);              
gen.setOffset(1, 0);             

gen.setBurstState(1, 'ON');      
gen.setBurstCycles(1, 10);        % cycle
gen.setBurstPeriod(1, 0.02);  
gen.setDelay(1,3.2e-6);
gen.setBurstSource(1, 'INT');    % 'BUS' or 'INT' 
gen.alignPhase();

%% Channel 2
gen.setWaveform(2, 'SQUARE');
gen.setImpedance(2, 50); 
gen.setFrequency(2, 200e3);        
gen.setAmplitude(2, 5);          
gen.setOffset(2, 2.5);
gen.setBurstState(2, 'ON');      
gen.setBurstCycles(2, 1);        % 1 cycle
gen.setBurstPeriod(2, 0.02);  
gen.setDelay(2,0);
gen.setBurstSource(2, 'INT'); 
%gen.setSquareDutyCycle(2,0.05)
gen.setIdleLevel(2, 'TOP')
gen.alignPhase();

%% Enable outputs
gen.outputOn(1);
gen.outputOn(2);
gen.alignPhase();
%% Disable outputs
gen.outputOff(1);
gen.outputOff(2);

%% xyz Motor initialization 
%% Y-Axis
ySerialNumber = '0021550514';  
yMotor = PIMotorController(ySerialNumber, '1');
yMotor.connect();
yMotor.setServo(true);
[minPosY, maxPosY, yRange] = yMotor.getTravelRange();
fprintf('Y-axis travel range: %.2f mm to %.2f mm\n', minPosY, maxPosY);
%% moving
movementY = 11.8;

if movementY >= 8 && movementY <= 15
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
movement = 14;   % 14.3mm,15

if movement >= 10 && movement <= 16
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

%%
pos_z = minPos +0;  %24.5mm
zMotor.moveAbs(pos_z);

%% Oscilloscope Initialization 
ipAddress = '10.48.7.251';
osc = T3DSO2502A(ipAddress);
osc.setInputBufferSize(2^22);   % Increase input buffer size to 4MB
osc.setTimeout(60);             % Set timeout to 60 seconds
osc.connect();

% Configure oscilloscope settings
% horizontal settings "time scale"
timeScale = 5e-6; % time per division
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
%% scan Z
% num_steps = 20;               % Number of motor steps
% step_size_mm = 0.001;         % 1 µm step size = 0.001 mm
% fprintf('Step size: %.4f mm (%.0f µm)\n', step_size_mm, step_size_mm * 1000);
% ipAddress = '10.48.7.251';
% %
% osc = T3DSO2502A(ipAddress);
% osc.setInputBufferSize(2^22);   % Increase input buffer size to 4MB
% osc.setTimeout(60);             % Set timeout to 60 seconds
% osc.connect();
% % Preallocate storage
% positions_mm = zeros(1, num_steps);
% data_all = cell(1, num_steps);
% t = [];
% 
% disp('Starting Scan downward...');
% for i = 1:num_steps
%     target_pos = pos_z + i * step_size_mm;
%     zMotor.moveAbs(target_pos);
%     osc.resetAveragingByOffset(1); % This need to be change based on Channel and the offset level 
%     pause(20);  % Wait for motor to settle
% 
%     current_pos = zMotor.getPosition();  % Read back actual motor position
%     fprintf('Current Position: %.4f mm\n', current_pos);
%     positions_mm(i) = current_pos;
% 
%     % Acquire data
%     %[data, t] = acquire_single_trace(osc, adcMaxValue, Fs_actual, t);
%     %data_all{i} = data;
% 
%     pause(1);  % Let pulse or system stabilize before next step
% end

%% Define Scan Parameters & Folders
stepSize = 0.1;     % 100 um in mm
scanLength = 1;     % total scan size = 1 mm

halfRange = scanLength / 2;

xPositions = pos_x_start + (-halfRange : stepSize : halfRange);
yPositions = pos_y_start + (-halfRange : stepSize : halfRange);
numX = length(xPositions);
numY = length(yPositions);

dateFolder = datestr(now, 'yyyy-mm-dd');
subFolderName = 'acquire_2Darray_xy_highfreq';
outputFolder = fullfile(pwd, dateFolder, subFolderName);

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

%% Raster scan nested loop
allData = cell(numY, numX);
allX = zeros(numY, numX);
allY = zeros(numY, numX);
t = [];
for i = 1:numY
    currentY = yPositions(i);
    yMotor.moveAbs(currentY);
    pause(2);
    
    for j = 1:numX
        currentX = xPositions(j);
        xMotor.moveAbs(currentX);
        osc.resetAveragingByOffset(2);
        pause(32);
        
        % Acquire signal
        [data, t] = acquire_single_trace(osc, adcMaxValue, Fs_actual, t);
        
        % Store
        allData{i, j} = data;
        allX(i, j) = currentX;
        allY(i, j) = currentY;
        
        fprintf('Point [%d,%d] saved: X=%.3f, Y=%.3f\n', i, j, currentX, currentY);
    end
end
save(fullfile(outputFolder, 'full_scan_100um_1mm_length_256ave_10cycles_20MHz_sample 162.mat'),'allData', 't', 'allX', 'allY', '-v7.3');
%save(fullfile(outputFolder, 'Test_1.mat'),'allData', 't', 'allX', 'allY', '-v7.3');


%%
[data, t] = acquire_single_trace(osc, adcMaxValue, Fs_actual, t);
save('echo_with_preampsonaxix.mat', 'data', 't')
%%
a= cell2mat(allData);
b=reshape(a,[size(allData{1},1),size(allData,1),size(allData,1)]);
amp = max(b,[],1);
% figure, imagesc(b(:,:))
showme(squeeze(amp))
d = dexplot;
d.data2plot = b(:,:);

%% return to the same position
initialX = pos_x_start;
initialY = pos_y_start;
xMotor.moveAbs(initialX);
yMotor.moveAbs(initialY);
fprintf('Returned to: X=%.3f, Y=%.3f\n', initialX, initialY);
%% motor disconnect
zMotor.disconnect()
xMotor.disconnect()
yMotor.disconnect()
%% clearing
clear ip
clear gen