function result = templateMatching(wave, sortData)
    %% Params Settings
    run(fullfile(fileparts(mfilename('fullpath')), 'config', 'defaultConfig.m'));
    sortOpts = getOr(sortData, "sortOpts", defaultSortOpts);
    CVCRThreshold = getOr(sortOpts, 'CVCRThreshold', defaultSortOpts.CVCRThreshold);

    %% Generate Templates
    if ~isfield(sortData, "templates") || isempty(sortData.templates)
        templates = genTemplates(sortData);
    else
        templates = sortData.templates;
    end

    [tNum, tLen] = size(templates);
    th = sortData.th;
    result.templates = templates;

    %% Spike Extraction
    disp('Extracting spikes...');
            
    try
        waveGPU = gpuArray(wave);
        [spikesGPU, spikeIndexAllGPU] = findpeaks(waveGPU, "MinPeakHeight", th, "MinPeakDistance", tLen / 2);
        [spikesAmp, spikeIndexAll] = gather(spikesGPU, spikeIndexAllGPU);
    catch
        warning("GPU device unavailable. Using CPU...");
        [spikesAmp, spikeIndexAll] = findpeaks(wave, "MinPeakHeight", th, "MinPeakDistance", tLen / 2);
    end

    if isempty(spikesAmp)
        error('No spikes detected in this channel');
    end

    %% Waveforms Extraction
    meanSpike = mean(spikesAmp);
    stdSpike = std(spikesAmp);

    % For this channel
    Waveforms = zeros(length(spikesAmp), tLen);
    spikeIndex = zeros(length(spikesAmp), 1);
    disp('Extracting Waveforms...');

    for sIndex = 1:length(spikesAmp)

        % Ignore the beginning and the end of the wave
        if spikeIndexAll(sIndex) - tLen / 2 > 0 && spikeIndexAll(sIndex) + tLen / 2 <= size(wave, 2)

            % Exclude possible artifacts
            if spikesAmp(sIndex) <= meanSpike + 3 * stdSpike
                Waveforms(sIndex, :) = wave(spikeIndexAll(sIndex) - tLen / 2 + 1:spikeIndexAll(sIndex) + tLen / 2);
                spikeIndex(sIndex) = spikeIndexAll(sIndex);
            end

        end

    end

    Waveforms(spikeIndex == 0, :) = [];
    spikeIndexAll(spikeIndex == 0) = [];

    result.chanIdx = 1;
    result.spikeTimeAll = (spikeIndexAll' - 1) / sortData.fs;
    result.wave = Waveforms;

    % MATLAB - pca
    [~, SCORE, latent] = pca(Waveforms);
    explained = latent / sum(latent);
    contrib = 0;

    for index = 1:size(explained, 1)
        contrib = contrib + explained(index);

        if contrib >= CVCRThreshold
            pcaData = SCORE(:, 1:index);
            break;
        end

    end

    result.pcaData = pcaData;

    %% Template Matching
    disp('Template matching...');
    convResult = cell(tNum, 1);
    result.clusterIdx = zeros(length(spikeIndexAll), 1);
    result.noiseClusterIdx = zeros(length(spikeIndexAll), 1);
    result.clusterCenter = zeros(tNum, size(pcaData, 2));

    for tIndex = 1:tNum
        temp = conv(wave, templates(tIndex, :), "same");
        convResult{tIndex} = temp(spikeIndexAll);

        meanValue = mean(convResult{tIndex});
        stdValue = std(convResult{tIndex});

        result.K = sortData.K;
        result.clusterIdx(convResult{tIndex} >= meanValue - stdValue * 3 & convResult{tIndex} <= meanValue + stdValue * 3) = tIndex;
        result.noiseClusterIdx(result.clusterIdx == 0 & result.noiseClusterIdx == 0) = tIndex;
        result.clusterCenter(tIndex, :) = mean(pcaData(result.clusterIdx == tIndex, :));
    end

    disp('Matching Done.');
    return;
end