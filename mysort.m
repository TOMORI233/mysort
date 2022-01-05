function sortResult = mysort(data)
    % Description: sort for TDT Block data in .mat format
    % Input:
    %     data: TDT Block data, specified as a struct
    % Output:
    %     sortResult: a struct array, each element of which is a result of one channel(electrode), containing fields:
    %                 - chanIdx: channel(electrode) number
    %                 - wave: spike waveforms of this channel(electrode), samples along row
    %                 - spikeTimeAll: spike time of raw wave data (if used), noise included
    %                 - clusterIdx: cluster index of each spike waveform sample, with 0 as noise
    %                 - K: optimum K used in K-means
    %                 - KArray: possible K values
    %                 - SSEs: elbow method result
    %                 - gaps: gap statistic result
    %                 - pcaData: PCA result of spike waveforms
    %                 - clusterCenter: samples along row, in PCA space

    addpath(genpath("Gap Statistic Algorithm\"));

    waves = data.streams.Wave.data;
    fs = data.streams.Wave.fs; % Hz
    channels = data.streams.Wave.channel;

    %% Params Settings
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
    t = (0:length(waves) - 1) / fs;
    figure;
    plot(t, waves, 'b');
    xlabel('Time (sec)');
    ylabel('Voltage (V)');

    sortOpts.th = input('Input th (V): ');

    %% Sort
    sortResult = sortMultiChannel(waves, channels, sortOpts);

    return;
end
