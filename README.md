# README

### Introduction

This sorting method is simply based on PCA and K-means.

**By now, overlapping spikes are ignored.**

`mysort` is for TDT Block data in .mat format. It should contain at least fields named `streams` or `snips`. `streams` should contain fields named `Wave`, which contains fields `data` (a m\*n matrix of entire recorded waves, channels along row), `fs` (sampling rate, in Hz) and `channel` (a m\*1 vector specifying channel numbers). `snips` should contain fields named `data` (a m\*p matrix of waveforms of spikes, waveform channel number along row and waveform points along column), `fs`, `chan` (a m\*1 vector specifying channel number of each waveform).

`batchSorting` is for waves or waveforms from any recording platform. For multi-channel data, it runs in loops of sorting every single channel, considering channels to be independent.

```matlab
% sortOpts (default)
% addpath(genpath(fileparts(mfilename('fullpath'))));
% run(fullfile(fileparts(mfilename('fullpath')), 'config', 'defaultConfig.m'));
sortOpts.th = 1e-5 * ones(1, size(waves, 1));
sortOpts.fs = 12207.03;
sortOpts.waveLength = 1.5e-3;
sortOpts.scaleFactor = 1e6;
sortOpts.CVCRThreshold = 0.9;
sortOpts.KselectionMethod = "gap";
KmeansOpts.KArray = 1:10;
KmeansOpts.maxIteration = 100;
KmeansOpts.maxRepeat = 3;
KmeansOpts.plotIterationNum = 0;
sortOpts.KmeansOpts = KmeansOpts;

% 1. Use raw wave data
% waves is an m×n matrix, with channels along row and sampling points along column
% channels is an m×1 column vector, which specifies the channel number of each wave sample
result = batchSorting(waves, channels, sortOpts);

% 2. Use extracted waveforms
% Waveforms is an m×n matrix, with channels along row and waveform points along column
% channels is an m×1 column vector, which specifies the channel number of each waveform
result = batchSorting([], channels, sortOpts, Waveforms);
```

### Instructions

See `mysort.m` for more detailed information.

1. To add `mysort` to your MATLAB path, in MATLAB command line type in

```matlab
>> addpath(genpath(your root path/mysort))
>> savepath
```

2. To sort your single-channel TDT block data

You can first use:

```matlab
sortResult = mysort(data, [], "origin"); % If K is left blank, an optimum K will be used
```

This will sort spike waveforms of your original block data using an optimum K generated by Gap Statistic for K-means.

If you are not satisfied with the original spike waveform length, you can specify `waveLength` in `mysort.m` and use:

```matlab
sortResult = mysort(data, [], "origin-reshape");
```

If you want to reselect a threshold for spikes, use:

```matlab
sortResult = mysort(data, [], "reselect");
```

Or use

```matlab
sortResult = mysort(data); % default, same with mysort(data, [], "reselect")
```

This will plot a time-wave curve of at most 100 seconds for preview. When a threshold (in volts) is input in MATLAB command line, the sorting process continues. For multi-channel sorting, `th` is required for every channel.

Still not satisfied? You can specify `CVCRThreshold` (cumulative variance contribution rate threshold, default: 0.9) for PC dimensions selection or convergence condition for K-means in `mKmeans.m` (usually a minimum ratio of relative cluster center shift in Euclidean distance, default: 0.1).

Also you can use MATLAB `pca` and `kmeans` functions instead of `mPCA` and `mKmeans` in `spikeSorting.m`.

3. To sort your multi-channel TDT block data

You can specify channels to sort with the second parameter of `mysort`. Usually `channels` is a vector containing the channel numbers to be sorted one by one. If it is left empty, all channels will be sorted.

```matlab
% data has 32 channels of waves
channels = [1, 2, 14, 20];
sortResult = mysort(data, channels, "reselect"); % sort channel 1,2,14,20 only
sortResult = mysort(data, [], "reselect"); % sort all 32 channels
sortResult = mysort(data, channels, "origin-reshape"); % sort original spike waveforms
```

4. If you consider some clusters as redundant ones, you can specify a K like this:

```matlab
sortResult = mysort(data, channels, "reselect", K); % specify a K
sortResult = mysort(data, channels, "reselect", "gap"); % default: use gap statistic to find an optimum K
sortResult = mysort(data, channels, "reselect", "elbow"); % use elbow method to find an optimum K
sortResult = mysort(data, channels, "reselect", "both"); % use gap statistic but also cal elbow method
sortResult = mysort(data, channels, "reselect", "preview"); % preview 3-D PCA data and input a K
```

5. For more detailed settings, specify your own `sortOpts`

```matlab
sortResult = mysort(..., sortOpts);
```

6. To view result, use:

```matlab
plotSSEorGap(sortResult); % select an optimum K
plotPCA(sortResult, [1, 2, 3]); % view clusters in 3-D PCA space. Also you can specify the second parameter with  a 2-element vector, which will show clusters in 2-D PCA space.
plotWave(sortResult); % view waves of different clusters
plotMSE(sortResult); % histogram of MSE of each template on each cluster
```
