clear; close all; clc;
addpath(genpath("..\mysort"));

%% Load Your Data Here
load('example.mat'); % TDT Block

%% Sort
% sortResult = mysort(data);
% sortResult = mysort(data, [], "origin", "preview");
% sortResult = mysort(data, [], "origin-reshape", "preview");
% sortResult = mysort(data, [], "origin-reshape", 2);
sortResult = mysort(data, [], "reselect", 2);

%% Plot
plotSSEorGap(sortResult);
plotPCA(sortResult, [1 2 3]);
plotWave(sortResult);

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
