function result = batchSorting(waves, channels, sortOpts, Waveforms)
    % Description: batch sorting result for each channel(electrode)
    %              If waves is specified, Waveforms of raw data will be generated.
    %              If Waveforms is specified, the input waves will be ignored.
    % Input:
    %     waves: raw wave data, channels(electrodes) along row
    %     channels: a channel(electrode) number column vector, each element specifies a channel(electrode) number for an entire wave.
    %               If Waveforms is specified, each element of channels specifies a channel number for each waveform.
    %               If left empty or 0, all channels will be sorted.
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
    %               - KmeansOpts: kmeans settings, a struct containing:
    %                             - KArray: possible K values for K-means (default: 1:10)
    %                             - maxIteration: maximum number of iterations (default: 100)
    %                             - maxRepeat: maximum number of times to repeat kmeans (default: 3)
    %                             - plotIterationNum: number of iterations to plot (default: 0)
    %                             - K: user-specified K. If left empty, an optimum K will be calculated and used (default: [])
    %     Waveforms: waveforms of spikes, from spikeTime - waveLength/2 to spikeTime + waveLength/2, channels along row
    % Output:
    %     result: a struct array, each element of which is a result of one channel(electrode), containing fields:
    %             - chanIdx: channel(electrode) number
    %             - wave: spike waveforms of this channel(electrode), samples along row
    %             - fs: sampling rate, in Hz
    %             - sortOpts: sort settings
    %             - spikeTimeAll: spike time of raw wave data (if used), noise included
    %             - clusterIdx: cluster index of each spike waveform sample, with 0 as noise
    %             - noiseClusterIdx: cluster index of each noise waveform sample, with 0 as non-noise
    %             - K: optimum K used in K-means
    %             - KArray: possible K values
    %             - SSEs: elbow method result
    %             - gaps: gap statistic result
    %             - pcaData: PCA result of spike waveforms
    %             - clusterCenter: samples along row, in PCA space
    % Usage:
    %     % 1. Use raw wave data
    %     % waves is an m×n matrix, with channels along row and sampling points along column
    %     % channels is an m×1 column vector, which specifies the channel number of each wave sample
    %     result = batchSorting(waves, channels, sortOpts);
    %     % 2. Use extracted waveforms
    %     % Waveforms is an m×n matrix, with channels along row and waveform points along column
    %     % channels is an m×1 column vector, which specifies the channel number of each waveform
    %     result = batchSorting([], channels, sortOpts, Waveforms);

    warning on;
    narginchk(1, 4);
    addpath(genpath(fileparts(mfilename('fullpath'))));

    run(fullfile(fileparts(mfilename('fullpath')), 'config', 'defaultConfig.m'));
    defaultKmeansOpts = defaultSortOpts.KmeansOpts;

    if nargin == 1 || (nargin > 1 && (isempty(channels) || isequal(channels, 0)))
        channels = (1:size(waves, 1))';
    end

    % sortOpts initialization
    if nargin < 3
        sortOpts = [];
    end

    sortOpts.th = getOr(sortOpts, 'th', defaultSortOpts.th);
    sortOpts.fs = getOr(sortOpts, 'fs', defaultSortOpts.fs);
    sortOpts.waveLength = getOr(sortOpts, 'waveLength', defaultSortOpts.waveLength); % sec
    sortOpts.scaleFactor = getOr(sortOpts, 'scaleFactor', defaultSortOpts.scaleFactor);
    sortOpts.CVCRThreshold = getOr(sortOpts, 'CVCRThreshold', defaultSortOpts.CVCRThreshold);
    sortOpts.KselectionMethod = getOr(sortOpts, 'KselectionMethod', defaultSortOpts.KselectionMethod);
    
    if isfield(sortOpts, "KmeansOpts")
        KmeansOpts.KArray = getOr(sortOpts.KmeansOpts, "KArray", defaultKmeansOpts.KArray);
        KmeansOpts.maxIteration = getOr(sortOpts.KmeansOpts, "maxIteration", defaultKmeansOpts.maxIteration);
        KmeansOpts.maxRepeat = getOr(sortOpts.KmeansOpts, "maxRepeat", defaultKmeansOpts.maxRepeat);
        KmeansOpts.plotIterationNum = getOr(sortOpts.KmeansOpts, "plotIterationNum", defaultKmeansOpts.plotIterationNum);
        KmeansOpts.K = getOr(sortOpts.KmeansOpts, "K", []);
    else
        KmeansOpts = defaultKmeansOpts;
    end

    scaleFactor = sortOpts.scaleFactor;
    CVCRThreshold = sortOpts.CVCRThreshold;
    KselectionMethod = sortOpts.KselectionMethod;

    if nargin < 4
        th = sortOpts.th; % V
        fs = sortOpts.fs; % Hz
        waveLength = sortOpts.waveLength; % sec

        if length(th) ~= length(channels)
            error('Number of ths not matched with number of channels');
        end

        % Waveforms: waveforms along row
        Waveforms = [];
        mChannels = []; % channel(electrode) number for each waveform
        spikeIndex = [];

        %% Waveforms Extraction
        % For each channel
        for cIndex = 1:length(channels)
            wave = waves(channels(cIndex), :);
            disp('Extracting spikes...');
            
            try
                waveGPU = gpuArray(wave);
                [spikesGPU, spikeIndexAllGPU] = findpeaks(waveGPU, "MinPeakHeight", th(cIndex), "MinPeakDistance", ceil(waveLength / 2 * fs));
                [spikes, spikeIndexAll] = gather(spikesGPU, spikeIndexAllGPU);
            catch
                warning("GPU device unavailable. Using CPU...");
                [spikes, spikeIndexAll] = findpeaks(wave, "MinPeakHeight", th(cIndex), "MinPeakDistance", ceil(waveLength / 2 * fs));
            end

            if isempty(spikes)
                warning(['No spikes detected in channel ', num2str(channels(cIndex))]);
                continue;
            end

            meanSpike = mean(spikes);
            stdSpike = std(spikes);

            % For this channel
            nWaveLength = length(1 - floor(sortOpts.waveLength / 2 * fs):floor(sortOpts.waveLength / 2 * fs));
            WaveformsTemp = zeros(length(spikes), nWaveLength);
            mChannelsTemp = zeros(length(spikes), 1);
            spikeIndexTemp = zeros(length(spikes), 1);
            disp('Extracting Waveforms...');

            for sIndex = 1:length(spikes)

                % Ignore the beginning and the end of the wave
                if spikeIndexAll(sIndex) - floor(waveLength / 2 * fs) > 0 && spikeIndexAll(sIndex) + floor(waveLength / 2 * fs) <= size(wave, 2)

                    % Exclude possible artifacts
                    if spikes(sIndex) <= meanSpike + 3 * stdSpike
                        WaveformsTemp(sIndex, :) = wave(spikeIndexAll(sIndex) - floor(waveLength / 2 * fs) + 1:spikeIndexAll(sIndex) + floor(waveLength / 2 * fs));
                        mChannelsTemp(sIndex) = channels(cIndex);
                        spikeIndexTemp(sIndex) = spikeIndexAll(sIndex);
                    end

                end

            end

            disp(['Channel ', num2str(channels(cIndex)), ' done. nSpikes = ', num2str(length(spikes))]);
            WaveformsTemp(mChannelsTemp == 0, :) = [];
            spikeIndexTemp(mChannelsTemp == 0) = [];
            mChannelsTemp(mChannelsTemp == 0) = [];
            Waveforms = [Waveforms; WaveformsTemp];
            mChannels = [mChannels; mChannelsTemp];
            spikeIndex = [spikeIndex; {spikeIndexTemp}];

            % Scale
            Waveforms = Waveforms * scaleFactor;
        end

        disp('Waveforms extraction done.');
    else
        mChannels = channels;
    end

    %% Batch Sorting
    channelUnique = unique(mChannels); % ascend

    if isempty(channelUnique)
        error('No channels specified');
    end

    disp('Sorting...');

    % For each channel
    for cIndex = 1:length(channelUnique)
        data = double(Waveforms(mChannels == channelUnique(cIndex), :));

        result(cIndex).chanIdx = channelUnique(cIndex);

        if isempty(data)
            continue;
        end

        result(cIndex).wave = data / scaleFactor;
        result(cIndex).sortOpts = sortOpts;
        result(cIndex).fs = fs;

        if isfield(sortOpts, "th")
            result(cIndex).th = sortOpts.th;
        end

        if exist("spikeIndex", "var")
            result(cIndex).spikeTimeAll = (spikeIndex{cIndex} - 1) / fs;
        end

        % Perform single channel sorting
        [clusterIdx, SSEs, gaps, optimumK, pcaData, clusterCenter, noiseClusterIdx] = spikeSorting(data, CVCRThreshold, KselectionMethod, KmeansOpts);

        result(cIndex).clusterIdx = clusterIdx;
        result(cIndex).noiseClusterIdx = noiseClusterIdx;
        result(cIndex).K = optimumK;
        result(cIndex).KArray = KmeansOpts.KArray;
        result(cIndex).SSEs = SSEs;
        result(cIndex).gaps = gaps;
        result(cIndex).pcaData = pcaData;
        result(cIndex).clusterCenter = clusterCenter;
        result(cIndex).templates = genTemplates(result(cIndex));

        disp(['Channel ', num2str(channelUnique(cIndex)), ' sorting finished. nClusters = ', num2str(optimumK)]);
    end

    disp('Sorting done.')
    return;
end
