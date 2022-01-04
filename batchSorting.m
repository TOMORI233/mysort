clear; close all; clc;

%% Load Your Data Here
addpath('example\');
load('example.mat'); % TDT Block

%% Params Settings
waves = data.streams.Wave.data;
fs = data.streams.Wave.fs; % Hz
channels = data.streams.Wave.channel;

t = (0:length(waves) - 1) / fs;

sortOpts.fs = fs;
sortOpts.waveLength = 2e-3; % sec
sortOpts.scaleFactor = 1e6;
sortOpts.CVCRThreshold = 0.9;
sortOpts.KselectionMethod = "gap";
KmeansOpts.KArray = 1:10;
KmeansOpts.maxIteration = 100;
KmeansOpts.maxRepeat = 5;
KmeansOpts.plotIterationNum = 0;
% KmeansOpts.K = 2;
sortOpts.KmeansOpts = KmeansOpts;

%% Select Th
figure;
plot(t, waves, 'b');
xlabel('Time (sec)');
ylabel('Voltage (V)');

sortOpts.th = input('Input th (V): ');
% sortOpts.th = 3e-5; % example

%% Sort
sortResult = sortMultiChannel(waves, channels, sortOpts);
% result = sortMultiChannel([], [], sortOpts, Waveforms, Electrode);

%% Plot
% load('result.mat');
visibilityOpt = "on";
saveFlag = false;
plotSSEorGap(sortResult, visibilityOpt, saveFlag);
plotPCA(sortResult, [1 2 3], visibilityOpt, saveFlag);
plotWave(sortResult, visibilityOpt, saveFlag);

%% Show Example
windowParams.window = [-1000 2000]; % ms
windowParams.step = 10; % ms
windowParams.binSize = 100; % ms
plotSettings.rasterHeightTotal = 0.8;
plotSettings.rasterWidth = 0.2;
plotSettings.gridAlpha = 0.3;
plotSettings.colors = ['k', 'b', 'r', 'g', 'y'];
plotSettings.visibilityOpt = "on";
normalizationSettings.baselineWindow = [-600 -100];
% normalizationSettings.plotOption = 'normalize';
normalizationSettings.plotOption = 'origin';

exampleResult.monkeyNum = 4;
exampleResult.cellNum = 5;
exampleResult.windowParams = windowParams;
exampleResult.normalizationSettings = normalizationSettings;
exampleResult.data = NoiseDurationResponseProcess(data, windowParams, normalizationSettings);
fig = plotNoiseDurationResponse(exampleResult, plotSettings, normalizationSettings);
set(fig, "Name", "Origin");

for cIndex = 1:sortResult.K
    exampleResult.data = NoiseDurationResponseProcess(data, windowParams, normalizationSettings, sortResult, cIndex);
    fig = plotNoiseDurationResponse(exampleResult, plotSettings, normalizationSettings);
    set(fig, "Name", ['Sorted - cluster ' num2str(cIndex)]);
end
