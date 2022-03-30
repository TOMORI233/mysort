function sortResult = mysort(data, channels, thOpt, KorMethod, sortOpts)
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
    %     sortOpts: a sorting settings struct (if left empty, default settings will be used), containing:
    %               - th: threshold for spike extraction, in volts (default: 1e-5)
    %               - fs: sampling rate, in Hz (default: 24414.0625)
    %               - waveLength: waveform length, in seconds (default: 1.5e-3)
    %               - scaleFactor: scale factor for waveforms (default: 1e+6)
    %               - CVCRThreshold: cumulative variance contribution rate threshold for principal components selection (default: 0.9)
    %               - KselectionMethod: method used to find an optimum K value for K-means
    %                                   - "elbow": use elbow method
    %                                   - "gap": use gap statistic (default)
    %                                   - "both": use gap statistic but also return SSE result of elbow method
    %                                   - "preview": plot 3-D PCA data and use an input K from user
    %               - reselectT0: for reselect mode (thOpt), starting time (in sec) of preview wave. (default: 0)
    %               - KmeansOpts: kmeans settings, a struct containing:
    %                             - KArray: possible K values for K-means (default: 1:10)
    %                             - maxIteration: maximum number of iterations (default: 100)
    %                             - maxRepeat: maximum number of times to repeat kmeans (default: 3)
    %                             - plotIterationNum: number of iterations to plot (default: 0)
    %                             - K: user-specified K. If left empty, an optimum K will be calculated and used (default: [])
    % Output:
    %     sortResult: a struct array, each element of which is a result of one channel(electrode), containing fields:
    %                 - chanIdx: channel(electrode) number
    %                 - wave: spike waveforms of this channel(electrode), samples along row
    %                 - sortOpts: sort settings
    %                 - th: threshold for spike extraction (if thOpts is "reselect")
    %                 - spikeTimeAll: spike time of raw wave data (if used), noise included. (unit: sec)
    %                 - clusterIdx: cluster index of each spike waveform sample, with 0 as noise
    %                 - noiseClusterIdx: cluster index of each noise waveform sample, with 0 as non-noise
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

    %% Params Validation and Initialization
    warning on;
    narginchk(1, 5);
    addpath(genpath(fileparts(mfilename('fullpath'))));

    if nargin < 2
        channels = [];
    end

    if nargin < 3
        thOpt = "reselect";
    end

    if nargin < 4
        KorMethod = "gap";
    end

    if nargin < 5
        sortOpts = [];
    end

    if isempty(channels)
        channels = 1:size(data.streams.Wave.data, 1);
    end

    waves = data.streams.Wave.data;

    %% Params Settings
    run(fullfile(fileparts(mfilename('fullpath')), 'config', 'defaultConfig.m'));
    sortOpts = getOrFull(sortOpts, defaultSortOpts);
    sortOpts.KmeansOpts = getOrFull(sortOpts.KmeansOpts, defaultSortOpts.KmeansOpts);

    if ~isfield(sortOpts, "fs") || isempty(sortOpts.fs)
        sortOpts.fs = data.streams.Wave.fs;
    end

    fs = sortOpts.fs;
    reselectT0 = getOr(sortOpts, 'reselectT0', defaultSortOpts.reselectT0); % sec

    if isa(KorMethod, 'double') && KorMethod == fix(KorMethod)
        sortOpts.KmeansOpts.K = KorMethod;
    elseif isa(KorMethod, 'string') || isa(KorMethod, 'char')
        sortOpts.KselectionMethod = KorMethod;
    else
        error('Invalid Parameter Input: KorMethod');
    end

    %% Sort
    if strcmp(thOpt, "reselect")
        %% Reselect Th for Spike and Waveform Extraction
        t = reselectT0:1 / fs:(min([reselectT0 + 200, size(waves, 2) / fs])); % preview at most 200-sec wave
        Fig = figure;

        if ~isfield(sortOpts, "th") || isempty(sortOpts.th) % th does not exist or is empty

            for cIndex = 1:length(channels)
                plot(t, waves(channels(cIndex), 1:length(t)), 'b'); drawnow;
                xlabel('Time (sec)');
                ylabel('Voltage (V)');
                xlim([reselectT0, reselectT0 + 10]); % show 10-sec wave
                title(['Channel ', num2str(channels(cIndex))]);
                sortOpts.th(cIndex) = validateInput("positive", ['Input th for channel ', num2str(channels(cIndex)), ' (unit: V): ']);
            end
            
        end

        try
            close(Fig);
        catch e
            disp(e);
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
        error('Invalid Parameter Input: thOpt');
    end

    return;
end
