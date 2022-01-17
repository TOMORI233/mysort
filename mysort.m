function sortResult = mysort(data, channels, thOpt, KorMethod)
    % Description: sorting for TDT Block data in .mat format
    % Input:
    %     data: TDT Block data, specified as a struct
    %           It should at least contain streams.Wave or snips.eNeu
    %     channels: channels to sort, specified as a vector of channel numbers.
    %               If left empty, all channels of Wave will be sorted. (default: [])
    %     thOpt: "origin" | "origin-reshape" | "reselect"(default)
    %             - "origin": use spike waveform of input data
    %             - "origin-reshape": use original spike data but reshape waveforms by user-specified wave length
    %             - "reselect": show at most 30 sec of wave for reselecting threshold for spikes extraction
    %     KorMethod: number K(double) or KselectionMethod(string or char)
    %                - K: number of clusters. If not specified, an optimum K generated by KselectionMethod will be used
    %                - KselectionMethod: method used to find an optimum K value for K-means
    %                                    - "elbow": use elbow method
    %                                    - "gap": use gap statistic (default)
    %                                    - "both": use gap statistic but also return SSE result of elbow method
    %                                    - "preview": plot 3-D PCA data and use an input K from user
    % Output:
    %     sortResult: a struct array, each element of which is a result of one channel(electrode), containing fields:
    %                 - chanIdx: channel(electrode) number
    %                 - wave: spike waveforms of this channel(electrode), samples along row
    %                 - th: threshold for spike extraction (if thOpts is "reselect")
    %                 - spikeTimeAll: spike time of raw wave data (if used), noise included. (unit: sec)
    %                 - clusterIdx: cluster index of each spike waveform sample, with 0 as noise
    %                 - K: optimum K used in K-means
    %                 - KArray: possible K values
    %                 - SSEs: elbow method result
    %                 - gaps: gap statistic result
    %                 - pcaData: PCA result of spike waveforms
    %                 - clusterCenter: samples along row, in PCA space
    % Usage:
    %     sortResult = mysort(data); % reselect th and use an optimum K generated by gap_statistic
    %     sortResult = mysort(data, [], "origin"); % use spike waveforms of input data and an optimum K
    %     sortResult = mysort(data, [], "origin-reshape"); % use spikes of input data but reshape each spike waveform with user-specified wave length
    %     sortResult = mysort(data, [], "reselect", 3); % reselect th for spikes and specify K as 3
    %     sortResult = mysort(data, [], "reselect", "preview"); % preview the 3-D PCA data and input a K
    %     spikes = sortResult.spikeTimeAll(sortResult.clusterIdx == 1); % spike times of cluster 1

    narginchk(1, 4);

    KselectionMethod = "gap";

    if nargin == 1
        channels = [];
        thOpt = "reselect";
    elseif nargin == 2
        thOpt = "reselect";
    elseif nargin == 4
        
        if isa(KorMethod, 'double')
            KmeansOpts.K = KorMethod;
        elseif isa(KorMethod, 'string') || isa(KorMethod, 'char')
            KselectionMethod = KorMethod;
        else
            error('参数KorMethod类型错误');
        end

    end

    if isempty(channels)
        channels = 1:size(data.streams.Wave.data, 1);
    end

    addpath(genpath("Gap Statistic Algorithm\"));

    waves = data.streams.Wave.data(channels, :);
    fs = data.streams.Wave.fs; % Hz

    %% Params Settings
    sortOpts.fs = fs;
    sortOpts.waveLength = 1.5e-3; % sec
    sortOpts.scaleFactor = 1e6;
    sortOpts.CVCRThreshold = 0.9;
    sortOpts.KselectionMethod = KselectionMethod;
    KmeansOpts.KArray = 1:10;
    KmeansOpts.maxIteration = 100;
    KmeansOpts.maxRepeat = 3;
    KmeansOpts.plotIterationNum = 0;
    sortOpts.KmeansOpts = KmeansOpts;

    %% Sort
    if strcmp(thOpt, "reselect")
        %% Reselect Th for Spike and Waveform Extraction
        t = 0:1 / fs:min([100, (size(waves, 2) - 1) * fs]); % show at most 100 sec wave
        figure;

        for cIndex = 1:length(channels)
            plot(t, waves(cIndex, 1:length(t)), 'b'); drawnow;
            xlim([0 30]); % show 30 sec
            xlabel('Time (sec)');
            ylabel('Voltage (V)');
            title(['Channel ', num2str(channels(cIndex))]);
            sortOpts.th(cIndex) = input(['Input th for channel ', num2str(channels(cIndex)), ' (unit: V): ']);
        end

        sortResult = batchSorting(waves, channels, sortOpts);
    elseif strcmp(thOpt, "origin-reshape")
        %% Use Original Spikes for Waveform Extraction by user-specified wave length
        t = (0:size(waves, 2) - 1) / fs;
        spikeTimeAll = data.snips.eNeu.ts; % sec
        channels = data.snips.eNeu.chan;
        Waveforms = zeros(length(spikeTimeAll), length(1 - floor(sortOpts.waveLength / 2 * fs):floor(sortOpts.waveLength / 2 * fs)));
        disp('Extracting Waveforms...');

        for sIndex = 1:length(spikeTimeAll)
            spikeTimeIndex = roundn(spikeTimeAll(sIndex) * fs, 0) - 1;

            if spikeTimeIndex - floor(sortOpts.waveLength / 2 * fs) > 0 && spikeTimeIndex + floor(sortOpts.waveLength / 2 * fs) <= length(t)
                Waveforms(sIndex, :) = waves(channels(sIndex), spikeTimeIndex - floor(sortOpts.waveLength / 2 * fs) + 1:spikeTimeIndex + floor(sortOpts.waveLength / 2 * fs));
            else
                channels(sIndex) = 0;
            end

        end

        Waveforms(channels == 0, :) = [];
        Waveforms = Waveforms * sortOpts.scaleFactor;
        spikeTimeAll(channels == 0) = [];
        channels(channels == 0) = [];
        disp('Waveforms extraction done.');
        sortResult = batchSorting([], channels, sortOpts, Waveforms);

        for cIndex = 1:length(sortResult)
            sortResult(cIndex).spikeTimeAll = spikeTimeAll(channels == sortResult(cIndex).chanIdx);
        end

    elseif strcmp(thOpt, "origin")
        %% Use Original Spike Waveforms of data
        Waveforms = data.snips.eNeu.data * sortOpts.scaleFactor;
        channels = data.snips.eNeu.chan;
        spikeTimeAll = data.snips.eNeu.ts;
        sortResult = batchSorting([], channels, sortOpts, Waveforms);

        for cIndex = 1:length(sortResult)
            sortResult(cIndex).spikeTimeAll = spikeTimeAll(channels == sortResult(cIndex).chanIdx);
        end

    else
        error('thOpt invalid!');
    end

    return;
end
