function sortResult = mysort(data, K)
    % Description: sort for TDT Block data in .mat format
    % Input:
    %     data: TDT Block data, specified as a struct
    %     K: number of clusters. If not specified, an optimum K generated by KselectionMethod will be used
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
    
    narginchk(1, 2);
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
    
    if nargin == 2
        KmeansOpts.K = K;
    end
    
    sortOpts.KmeansOpts = KmeansOpts;

    %% Select Th
    % t = (0:length(waves) - 1) / fs;
    t = 0:1 / fs:30; % show 30 sec wave
    figure;
    plot(t, waves(1:length(t)), 'b');
    xlabel('Time (sec)');
    ylabel('Voltage (V)');

    sortOpts.th = input('Input th (V): ');

    %% Sort
    sortResult = sortMultiChannel(waves, channels, sortOpts);

    return;
end