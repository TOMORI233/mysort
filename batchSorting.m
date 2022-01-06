function result = batchSorting(waves, channels, sortOpts, Waveforms)
    % Description: batch sorting result for each channel(electrode)
    %              If waves is specified, Waveforms of raw data will be generated.
    %              If Waveforms is specified, the input waves will be ignored.
    % Input:
    %     waves: raw wave data, channels(electrodes) along row
    %     channels: a channel(electrode) number column vector, each element
    %               specifies a channel(electrode) number for an entire
    %               wave. If Waveforms is specified, each element of
    %               channels specifies a channel number for each waveform.
    %     sortOpts: a sorting settings struct containing:
    %               - th: threshold for spike extraction, in volts (default: 1e-5)
    %               - fs: sampling rate, in Hz
    %               - waveLength: waveform length, in seconds (default: 1.5e-3)
    %               - scaleFactor: scale factor for waveforms (default: 1e+6)
    %               - CVCRThreshold: cumulative variance contribution rate threshold for principal components selection (default: 0.9)
    %               - KselectionMethod: "elbow" or "gap", method used to find an optimum K value for K-means
    %                                   - "elbow": use elbow method
    %                                   - "gap": use gap statistic (default)
    %                                   - "both": use gap statistic but also return SSE result of elbow method
    %               - KmeansOpts: kmeans settings, a struct containing:
    %                                   - KArray: possible K values for K-means (default: 1:10)
    %                                   - maxIteration: maximum number of iterations (default: 100)
    %                                   - maxRepeat: maximum number of times to repeat kmeans (default: 5)
    %                                   - plotIterationNum: number of iterations to plot (default: 0)
    %                                   - K: user-specified K. If left empty, an optimum K will be calculated and used
    %     Waveforms: waveforms of spikes, from spikeTime - waveLength/2 to spikeTime + waveLength/2, channels along row
    % Output:
    %     result: a struct array, each element of which is a result of one channel(electrode), containing fields:
    %             - chanIdx: channel(electrode) number
    %             - wave: spike waveforms of this channel(electrode), samples along row
    %             - spikeTimeAll: spike time of raw wave data (if used), noise included
    %             - clusterIdx: cluster index of each spike waveform sample, with 0 as noise
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
    %     result = sortMultiChannel(waves, channels, sortOpts);
    %     % 2. Use extracted waveforms
    %     % Waveforms is an m×n matrix, with channels along row and waveform points along column
    %     % channels is an m×1 column vector, which specifies the channel number of each waveform
    %     result = sortMultiChannel([], channels, sortOpts, Waveforms);

    narginchk(3, 4);

    scaleFactor = sortOpts.scaleFactor;
    CVCRThreshold = sortOpts.CVCRThreshold;
    KselectionMethod = sortOpts.KselectionMethod;
    KmeansOpts = sortOpts.KmeansOpts;

    if nargin == 3
        th = sortOpts.th; % V
        fs = sortOpts.fs; % Hz
        waveLength = sortOpts.waveLength; % sec

        % Waveforms: waveforms along row
        Waveforms = [];
        mChannels = []; % channel(electrode) number for each waveform
        spikeIndex = [];

        %% Waveforms Extraction
        % For each channel
        for eIndex = 1:length(channels)
            wave = waves(eIndex, :);
            [spikes, spikeIndexAll] = findpeaks(wave, "MinPeakHeight", th, "MinPeakDistance", ceil(waveLength / 2 * fs));
            meanSpike = mean(spikes);
            stdSpike = std(spikes);
            spikeIndexTemp = [];
            disp('Waveforms extraction...');

            for sIndex = 1:length(spikeIndexAll)

                % Ignore the beginning and the end of the wave
                if spikeIndexAll(sIndex) - floor(waveLength / 2 * fs) > 0 && spikeIndexAll(sIndex) + floor(waveLength / 2 * fs) <= size(wave, 2)

                    % Exclude possible artifacts
                    if spikes(sIndex) <= meanSpike + 3 * stdSpike
                        Waveforms = [Waveforms; wave(spikeIndexAll(sIndex) - floor(waveLength / 2 * fs) + 1:spikeIndexAll(sIndex) + floor(waveLength / 2 * fs))];
                        mChannels = [mChannels; channels(eIndex)];
                        spikeIndexTemp = [spikeIndexTemp; spikeIndexAll(sIndex)];
                    end

                end

            end

            disp('Waveforms extraction done.');
            spikeIndex = [spikeIndex; {spikeIndexTemp}];

            % Scale
            Waveforms = Waveforms * scaleFactor;
        end

    elseif nargin == 4
        mChannels = channels;
    end

    %% Batch Sorting
    channelUnique = unique(mChannels);
    disp('Sorting...');

    % For each channel
    for eIndex = 1:length(channelUnique)
        data = double(Waveforms(mChannels == channelUnique(eIndex), :));

        result(eIndex).chanIdx = channelUnique(eIndex);
        result(eIndex).wave = data / scaleFactor;

        if isfield(sortOpts, "th")
            result(eIndex).th = sortOpts.th;
        end

        if exist("spikeIndex", "var")
            result(eIndex).spikeTimeAll = (spikeIndex{eIndex} - 1) / fs;
        end

        % Perform single channel sorting
        [clusterIdx, SSEs, gaps, optimumK, pcaData, clusterCenter] = spikeSorting(data, CVCRThreshold, KselectionMethod, KmeansOpts);
        
        result(eIndex).clusterIdx = clusterIdx;
        result(eIndex).K = optimumK;
        result(eIndex).KArray = KmeansOpts.KArray;
        result(eIndex).SSEs = SSEs;
        result(eIndex).gaps = gaps;
        result(eIndex).pcaData = pcaData;
        result(eIndex).clusterCenter = clusterCenter;
    end

    disp('Sorting done.')
    return;
end
