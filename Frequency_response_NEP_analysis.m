%% Freq response  
%Load file for the FP signal and echo
%A = load('echo_trace_2.mat');
B = load('sensor182_withavg256_1cycle_5Vpp_90MHz_79.56MHz.mat');

%allData_echo = getData(A);   % it is in the help section/grabs data_all OR allData, whichever exists
allData_sig = getData(B);

t = B.t;
t = t(:).';                      % row time vector, same as the echo dimension

% Select from the dataset optical signal and the echo as well
sig    = allData_sig{1,1};
%trace_echo = allData_echo{1,1};

% Sampling frequency
dt = t(2) - t(1);
Fs = 1 / dt;
N  = length(t);

%% signal — windowed around maximum peak 
[~, MaxPeak] = max(abs(sig));
time_Peak = t(MaxPeak);

win5  = 0.05e-6;                          
mask5 = (t >= time_Peak - win5) & (t <= time_Peak + win5);
mask5 = mask5(:);

sig_Windowed = zeros(size(sig));
hammWinSig = hamming(nnz(mask5)); %% this is the hamming window
sig_Windowed(mask5) = sig(mask5) .* hammWinSig; %% multiple the window with the signal

%% The echo signal filtering 
% tMin = 1e-6; % choosing this time just filter the echo not the excitation signal
% [pkVals, pkLocs] = findpeaks(abs(trace_echo));
% validPk = t(pkLocs) > tMin;
% pkVals  = pkVals(validPk);
% pkLocs  = pkLocs(validPk);
% [~, maxRel] = max(pkVals);
% pkIdxEcho   = pkLocs(maxRel);
% tPeakEcho   = t(pkIdxEcho);
% 
% winE  = 0.2e-6;
% maskE = (t >= tPeakEcho - winE) & (t <= tPeakEcho + winE);
% maskE = maskE(:);
% 
% echoWindowed = zeros(size(trace_echo));
% hammWinE = hamming(nnz(maskE));
% echoWindowed(maskE) = trace_echo(maskE) .* hammWinE;

%% Normalize thethe time-domain of both FP_signals and the echo 
% This helps to scale the amplitide of the echo to gether with the FP
% signal
sig25Norm = sig_Windowed / max(abs(sig_Windowed));
% echoNorm = echoWindowed / max(abs(echoWindowed));

%% FFT analysis
%  25 MHz spectrum 
Y5   = fft(sig_Windowed);
P2   = abs(Y5 / N);
P1_5 = P2(1:floor(N/2)+1); % To prevent the mirrors effect
P1_5(2:end-1) = 2 * P1_5(2:end-1);

%  echo spectrum 
% YE   = fft(echoWindowed);
% P2   = abs(YE / N);
% P1_E = P2(1:floor(N/2)+1);
% P1_E(2:end-1) = 2 * P1_E(2:end-1);

f = Fs * (0:floor(N/2)) / N;

%% Normalized the amplitude spectra 
P1_5_Norm = P1_5 / max(P1_5);
% P1_E_Norm = P1_E / max(P1_E);

%%  Ploting 
figure;
%  Top signals 
subplot(2, 1, 1);
plot(t, sig25Norm, 'b', 'LineWidth', 1); hold on;
% plot(t, echoNorm, 'r', 'LineWidth', 1); hold off;
xlabel('Time (s)');
xlim([0.1e-5 2e-5])
ylabel('Normalized amplitude');
legend('90 MHz FP signal', '90 MHz Echo signal', 'Location', 'best');
grid on;
axis tight;
xlim([0.1e-5 10e-6])

%  Bottom amplitude 
subplot(2, 1, 2);
plot(f / 1e6, P1_5_Norm, 'b', 'LineWidth', 1); hold on;
% plot(f / 1e6, P1_E_Norm, 'r', 'LineWidth', 1); hold off;
xlabel('Frequency (MHz)');
ylabel('Normalized |amplitude|');
legend('90 MHz FP signal', '30 MHz Echo signal', 'Location', 'best');
grid on;
axis tight;
xlim([2 140]);
%% NEP analysis
%  Load data
B = load('sensor183_withavg256_10cycle_5Vpp_30MHz_79.65MHz.mat');
allData = B.data_all;
t = B.t(:).';                                 % for making the time trace (1x50000), same as the echo dimension the same as freq response

%  Applied pressure it is take from the Martin results diractly from the plot
pressure_kPa = 484;
pressure_Pa  = pressure_kPa * 1e3;            % Pa

% Define the signal and noice windows 
tSigStart   = 2e-6;     tSigStop   = 4e-6;   
tNoiseStart = 8e-6;    tNoiseStop = 10e-6;   

sigMask   = (t >= tSigStart)   & (t <= tSigStop);
noiseMask = (t >= tNoiseStart) & (t <= tNoiseStop);

% Loop over all cells in data for SNR calcuation after offset correction
nCells     = numel(allData);
SNR_all    = zeros(nCells, 1);
sigMax_all = zeros(nCells, 1);
noise_all  = zeros(nCells, 1);

for k = 1:nCells
    sig = allData{k}(:);                      
    sig = sig - mean(sig);                    % offset correction

    sigMax_all(k) = max(abs(sig(sigMask)));   % peak inside signal window
    sigPtp_all(k) = max(sig(sigMask))-min(sig(sigMask));   % peak inside signal window

    noise_all(k)  = std(sig(noiseMask));      % std noise (V) in noise window
    %RMS_all(k)  = rms(sig(noiseMask));      % RMS noise (V) in noise window

    SNR_all(k)    = sigPtp_all(k) / noise_all(k); % SNR
end

%  Pick the best-SNR cell 
[bestSNR, bestIdx] = max(SNR_all);

% NEP for the best-SNR signal 
sigMax_V   = sigMax_all(bestIdx);
noiseRMS_V = noise_all(bestIdx);

sensitivity_V_per_Pa = sigMax_V / pressure_Pa;          % V/Pa
NEP_Pa  = noiseRMS_V / sensitivity_V_per_Pa;            % Pa
NEP_kPa = NEP_Pa / 1e3;                                 % kPa (for display)

fprintf('Pressure:      %.2f kPa  (%.0f Pa)\n', pressure_kPa, pressure_Pa);
fprintf('Sensitivity:   %.3e V/Pa\n', sensitivity_V_per_Pa);
fprintf('NEP:            %.5f kPa)\n', NEP_kPa);
fprintf('SNR:            %.5f dB)\n', bestSNR);
%%  Plot the best-SNR trace with both windows marked 
sigBest = allData{bestIdx}(:);                % choose the best signal for plot
sigBest = sigBest - mean(sigBest);            % offset correction


figure; set(gcf, 'Color', 'w', 'Units', 'inches', 'Position', [1 1 8 4]);
plot(t*1e6, sigBest, 'Color', [0.20 0.40 0.75], 'LineWidth', 1.2); hold on;

% Shade the SIGNAL window (green)
yl = ylim;
patch([tSigStart tSigStop tSigStop tSigStart]*1e6, ...
      [yl(1) yl(1) yl(2) yl(2)], ...
      [0.80 0.95 0.80], 'EdgeColor', 'none', 'FaceAlpha', 0.5);

% Shade the NOISE window (red)
patch([tNoiseStart tNoiseStop tNoiseStop tNoiseStart]*1e6, ...
      [yl(1) yl(1) yl(2) yl(2)], ...
      [1.00 0.85 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.5);


xlabel('Time (\mus)'); ylabel('Amplitude (V)');
grid on; box on;
%% ---- helper: return whichever data field the file uses ----
function d = getData(s)
    if     isfield(s, 'data_all'), d = s.data_all;
    elseif isfield(s, 'allData'),  d = s.allData;
    else,  error('No data field. Fields: %s', strjoin(fieldnames(s), ', '));
    end
end
