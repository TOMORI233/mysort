function sortResult = batchSorting(waves, channels, sortOpts, type)
    % Description: batch sorting result for each channel(electrode)
    % Input:
    %     waves: 1. If type is set "raw_wave", input [waves] will be identified as raw wave data specified as [channels, waves].
    %            2. If type is set "spike_wave", input [waves] will be identified as spike wave specified as [spikes, waveforms].
    %               Waveforms are data from spikeTime - waveLength/2 to spikeTime + waveLength/2.
    %     channels: a channel(electrode) number column vector, each element specifies a channel(electrode) number for an entire wave.
    %               If [type] is set "spike_wave", each element of [channels] specifies the channel
    %               number of each spike waveform and size(channels,1)==size(waves,1).
    %               If [type] is set "raw_wave" and [channels] is left empty or 0, all channels will
    %               be sorted, otherwise size(channels,1)==size(waves,1).
    %     sortOpts: a sorting settings struct (if left empty, default settings will be used), containing:
    %               - th: threshold for spike extraction, in volts (default: [])
    %               - fs: sampling rate, in Hz (default: [], using fs of [data])
    %                     If you use batchSorting only (instead of using mysort), you should specify [fs] here.
    %               - waveLength: waveform length, in sec (default: 1.5e-3)
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
    %     type: "raw_wave" or "spike_wave"
    % Output:
    %     sortResult: a struct array, each element of which is a result of one channel(electrode), containing fields:
    %                 - chanIdx: channel(electrode) number
    %                 - wave: spike waveforms of this channel(electrode), samples along row
    %                 - spikeAmp: spike amplitude vector
    %                 - sortOpts: sort settings
    %                 - spikeTimeAll: spike time of raw wave data (if used), noise included
    %                 - clusterIdx: cluster index of each spike waveform sample, with 0 as noise
    %                 - noiseClusterIdx: cluster index of each noise waveform sample, with 0 as non-noise
    %                 - K: optimum K used in K-means
    %                 - KArray: possible K values
    %                 - SSEs: elbow method result
    %                 - gaps: gap statistic result
    %                 - pcaData: PCA result of spike waveforms
    %                 - clusterCenter: samples along row, in PCA space
    % Usage:
    %     % 1. Use raw wave data
    %     % waves is an m×N matrix, with channels along row and sampling points along column
    %     % channels is an m×1 column vector, which specifies the channel number of each wave sample
    %     sortResult = batchSorting(waves, channels, sortOpts);
    %     % 2. Use extracted waveforms
    %     % Waveforms is an M×n matrix, with channels along row and waveform points along column
    %     % channels is an M×1 column vector, which specifies the channel number of each waveform
    %     sortResult = batchSorting(Waveforms, channels, sortOpts, "spike_wave");

    warning on;
    narginchk(1, 4);
    addpath(genpath(fileparts(mfilename('fullpath'))));

    if nargin == 1 || (nargin > 1 && (isempty(channels) || isequal(channels, 0)))
        channels = (1:size(waves, 1))';
    end

    if nargin < 3
        sortOpts = [];
    end

    if nargin < 4
        type = "raw_wave";
    end

    % sortOpts initialization
    run(fullfile(fileparts(mfilename('fullpath')), 'config', 'defaultConfig.m'));
    sortOpts = getOrFull(sortOpts, defaultSortOpts);
    sortOpts.KmeansOpts = getOrFull(sortOpts.KmeansOpts, defaultSortOpts.KmeansOpts);
    
    KmeansOpts = sortOpts.KmeansOpts;
    scaleFactor = sortOpts.scaleFactor;
    CVCRThreshold = sortOpts.CVCRThreshold;
    KselectionMethod = sortOpts.KselectionMethod;

    switch type
        case "raw_wave"
            disp("Sorting with raw wave");
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
                disp('Applying highpass filter...');
                wave = waves(channels(cIndex), :);
                wave = mysortFilter(wave, fs);
                
                disp('Extracting spikes...');
                
                try
                    waveGPU = gpuArray(wave);
                    [spikeAmpGPU, spikeIndexAllGPU] = findpeaks(waveGPU, "MinPeakHeight", th(cIndex), "MinPeakDistance", ceil(waveLength / 2 * fs));
                    [spikeAmp, spikeIndexAll] = gather(spikeAmpGPU, spikeIndexAllGPU);
                catch
                    warning("GPU device unavailable. Using CPU...");
                    [spikeAmp, spikeIndexAll] = findpeaks(wave, "MinPeakHeight", th(cIndex), "MinPeakDistance", ceil(waveLength / 2 * fs));
                end
    
                if isempty(spikeAmp)
                    warning(['No spikes detected in channel ', num2str(channels(cIndex))]);
                    continue;
                end
    
                meanSpikeAmp = mean(spikeAmp);
                stdSpikeAmp = std(spikeAmp);
    
                % For this channel
                nWaveLength = length(1 - floor(sortOpts.waveLength / 2 * fs):floor(sortOpts.waveLength / 2 * fs));
                WaveformsTemp = zeros(length(spikeAmp), nWaveLength);
                mChannelsTemp = zeros(length(spikeAmp), 1);
                spikeIndexTemp = zeros(length(spikeAmp), 1);
                disp('Extracting Waveforms...');
    
                for sIndex = 1:length(spikeAmp)
    
                    % Ignore the beginning and the end of the wave
                    if spikeIndexAll(sIndex) - floor(waveLength / 2 * fs) > 0 && spikeIndexAll(sIndex) + floor(waveLength / 2 * fs) <= size(wave, 2)
    
                        % Exclude possible artifacts
                        if spikeAmp(sIndex) <= meanSpikeAmp + 3 * stdSpikeAmp
                            WaveformsTemp(sIndex, :) = wave(spikeIndexAll(sIndex) - floor(waveLength / 2 * fs) + 1:spikeIndexAll(sIndex) + floor(waveLength / 2 * fs));
                            mChannelsTemp(sIndex) = channels(cIndex);
                            spikeIndexTemp(sIndex) = spikeIndexAll(sIndex);
                        end
    
                    end
    
                end
    
                disp(['Channel ', num2str(channels(cIndex)), ' done. nSpikes = ', num2str(length(spikeAmp))]);
                WaveformsTemp(mChannelsTemp == 0, :) = [];
                spikeIndexTemp(mChannelsTemp == 0) = [];
                mChannelsTemp(mChannelsTemp == 0) = [];
                Waveforms = [Waveforms; WaveformsTemp];
                mChannels = [mChannels; mChannelsTemp];
                spikeIndex = [spikeIndex; {spikeIndexTemp}];
    
                % Scale
                Waveforms = Waveforms * scaleFactor;
            end
    
            disp('Waveforms extraction done');
        case "spike_wave"
            disp("Sorting with spike waveforms");
            Waveforms = waves;
            mChannels = channels;
        otherwise
            error("Invalid type input");
    end

    %% Batch Sorting
    channelUnique = unique(mChannels); % ascend

    if isempty(channelUnique)
        error('No channels specified');
    end

    % For each channel
    for cIndex = 1:length(channelUnique)
        disp(['Sorting CH ', num2str(channelUnique(cIndex)), '...']);
        data = double(Waveforms(mChannels == channelUnique(cIndex), :));

        sortResult(cIndex).chanIdx = channelUnique(cIndex);

        if isempty(data)
            continue;
        end

        sortResult(cIndex).wave = data / scaleFactor;
        sortResult(cIndex).spikeAmp = max(sortResult(cIndex).wave, [], 2);
        sortResult(cIndex).sortOpts = sortOpts;

        if isfield(sortOpts, "th")
            sortResult(cIndex).th = sortOpts.th;
        end

        if exist("spikeIndex", "var")
            sortResult(cIndex).spikeTimeAll = (spikeIndex{cIndex} - 1) / fs;
        end

        % Perform single channel sorting
        [clusterIdx, SSEs, gaps, optimumK, pcaData, clusterCenter, noiseClusterIdx] = spikeSorting(data, CVCRThreshold, KselectionMethod, KmeansOpts);

        sortResult(cIndex).clusterIdx = clusterIdx;
        sortResult(cIndex).noiseClusterIdx = noiseClusterIdx;
        sortResult(cIndex).K = optimumK;
        sortResult(cIndex).KArray = KmeansOpts.KArray;
        sortResult(cIndex).SSEs = SSEs;
        sortResult(cIndex).gaps = gaps;
        sortResult(cIndex).pcaData = pcaData;
        sortResult(cIndex).clusterCenter = clusterCenter;
        sortResult(cIndex).templates = genTemplates(sortResult(cIndex));

        disp(['Channel ', num2str(channelUnique(cIndex)), ' sorting finished. nClusters = ', num2str(optimumK)]);
    end

    disp('Sorting done')
    return;
end
