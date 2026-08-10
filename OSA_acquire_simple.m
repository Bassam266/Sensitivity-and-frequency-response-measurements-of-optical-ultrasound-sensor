%% OSA_acquire_simple.m
% Minimal Yokogawa OSA acquisition.
% Connects to the OSA, runs a single sweep, retrieves the spectrum,
% plots it, and optionally saves it to a .mat file.
%
% Requires on the MATLAB path:
%   YokogawaOSA.m and its dependencies.

clear;
clc;
close all;

%% ---------------- SETTINGS ----------------

osaConfig = struct();
osaConfig.ip = '10.48.20.178';   % Change if DHCP assigns another OSA IP
osaConfig.port = '10001';
osaConfig.user = 'yokogawa';
osaConfig.password = '1234';
osaConfig.timeout_ms = 60000;

saveData = false;                % Set true to save the spectrum
saveFolder = pwd;                % Where to save if saveData = true

%% ---------------- CONNECT ----------------

fprintf('Connecting to Yokogawa OSA at %s...\n', osaConfig.ip);

osa = YokogawaOSA( ...
    'ip', osaConfig.ip, ...
    'port', osaConfig.port, ...
    'user', osaConfig.user, ...
    'password', osaConfig.password, ...
    'timeout', osaConfig.timeout_ms);

osa.SetASEDefaults('timeout', osaConfig.timeout_ms);

osa.GetID();
fprintf('Connected instrument: %s\n', strtrim(char(osa.buffer.string)));

%% ---------------- ACQUIRE ----------------

fprintf('Running single sweep and retrieving spectrum...\n');

osa.SweepAndRetrieve();

lambda = osa.data.X(:);   % wavelength [m]
Y = osa.data.Y(:);        % intensity  [a.u. or dBm, per OSA settings]

fprintf('Acquired %d points, %.3f to %.3f nm\n', ...
    numel(lambda), min(lambda) * 1e9, max(lambda) * 1e9);

%% ---------------- PLOT ----------------

figure(1);
plot(lambda * 1e9, Y);
xlabel('Wavelength [nm]');
ylabel('Intensity');
title('OSA spectrum');
grid on;

%% ---------------- SAVE (optional) ----------------

if saveData
    timestr = datestr(now, 'yyyy-mm-dd_HHMMSS');
    saveFile = fullfile(saveFolder, ['OSA_spectrum_' timestr '.mat']);
    units = osa.units;
    measParams = osa.measParams;
    save(saveFile, 'lambda', 'Y', 'units', 'measParams');
    fprintf('Saved spectrum to:\n%s\n', saveFile);
end

%% ---------------- CLOSE ----------------

delete(osa);
fprintf('Done. OSA connection closed.\n');
