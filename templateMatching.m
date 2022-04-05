function sortResult = templateMatching(data, sortResult0)
    % Description: sort TDT data with template matching.
    % Assume that data0 and data1 are different recorded protocol data from one cell or from one long-term recording data.
    % Sort data0 with mysort to generate spike waveform templates and apply template matching to data1.
    % The template matching algorithm is based on sum of sqaure error (SSE).
    % The basic principal is that the amplitude of spikes from the same cell follows a Gaussian normal distribution.
    % Thus, SSEs between a template and waveforms followa a chi-square distribution.
    % Using normalized PCA data for SSE calculation can better characterize similarity.
    % The confidence interval is [0, chi2inv(0.95, df)], where df is the number of principal components.
    %
    % Input:
    %     data: TDT Block data, specified as a struct
    %           It should at least contain streams.Wave.data and streams.Wave.fs
    %     sortResult0: a struct of sorting result generated by mysort
    % Output:
    %     sortResult: sorting result of mysort. Refer to mysort.m for more information
    % Usage:
    %     sortResult0 = mysort(data0, [], "reselect", "preview");
    %     sortResult = templateMatching(data1, sortResult0);

    addpath(genpath(fileparts(mfilename('fullpath'))));
    warning on;

    %% Params Settings
    run(fullfile(fileparts(mfilename('fullpath')), 'config', 'defaultConfig.m'));
    sortOpts = getOrFull(sortResult0.sortOpts, defaultSortOpts);
    sortOpts.KmeansOpts = getOrFull(sortOpts.KmeansOpts, defaultSortOpts.KmeansOpts);
    
    if ~isfield(sortOpts, "fs") || isempty(sortOpts.fs)
        sortOpts.fs = data.streams.Wave.fs;
    end

    fs = sortOpts.fs;
    CVCRThreshold = sortOpts.CVCRThreshold;

    wave = data.streams.Wave.data(1, :);
    [~, waveSize] = size(sortResult0.wave);
    th = sortResult0.th;
    K = sortResult0.K;
    templates = getOr(sortResult0, "templates", genTemplates(sortResult0));
    sortResult.K = K;
    sortResult.sortOpts = sortOpts;

    %% Spike Extraction
    disp('Extracting spikes...');
            
    try
        waveGPU = gpuArray(wave);
        [spikesGPU, spikeIndexAllGPU] = findpeaks(waveGPU, "MinPeakHeight", th, "MinPeakDistance", waveSize / 2);
        [spikesAmp, spikeIndexAll] = gather(spikesGPU, spikeIndexAllGPU);
    catch
        warning("GPU device unavailable. Using CPU...");
        [spikesAmp, spikeIndexAll] = findpeaks(wave, "MinPeakHeight", th, "MinPeakDistance", waveSize / 2);
    end

    if isempty(spikesAmp)
        error('No spikes detected in this channel');
    end

    %% Waveforms Extraction
    meanSpike = mean(spikesAmp);
    stdSpike = std(spikesAmp);

    % For this channel
    Waveforms = zeros(length(spikesAmp), waveSize);
    spikeIndex = zeros(length(spikesAmp), 1);
    disp('Extracting Waveforms...');

    for sIndex = 1:length(spikesAmp)

        % Ignore the beginning and the end of the wave
        if spikeIndexAll(sIndex) - floor(waveSize / 2) > 0 && spikeIndexAll(sIndex) + floor(waveSize / 2) <= size(wave, 2)

            % Exclude possible artifacts
            if spikesAmp(sIndex) <= meanSpike + 3 * stdSpike
                Waveforms(sIndex, :) = wave(spikeIndexAll(sIndex) - floor(waveSize / 2) + 1:spikeIndexAll(sIndex) + floor(waveSize / 2));
                spikeIndex(sIndex) = spikeIndexAll(sIndex);
            end

        end

    end

    Waveforms(spikeIndex == 0, :) = [];
    spikeIndexAll(spikeIndex == 0) = [];

    sortResult.chanIdx = 1;
    sortResult.spikeTimeAll = (spikeIndexAll' - 1) / fs;
    sortResult.wave = Waveforms;

    %% PCA
    % [Waveforms; templates]
    % Find PCA result of templates in a different PCA space
    % MATLAB - pca
    [coeff, SCORE, latent] = pca([Waveforms; templates] * sortResult0.sortOpts.scaleFactor);
    explained = latent / sum(latent);
    contrib = 0;

    for index = 1:size(explained, 1)
        contrib = contrib + explained(index);

        if contrib >= CVCRThreshold
            pcaData = SCORE(1:end - K, 1:index);

            temp = normalize(SCORE(:, 1:index), 1);
            pcaData_norm = temp(1:end - K, :);
            C_norm = temp(end - K + 1:end, :);
            break;
        end

    end

    sortResult.pcaData = pcaData;

    %% Template Matching with PCA Data
    disp('Template matching...');
    SSE_norm = zeros(size(pcaData_norm, 1), K);

    for kIndex = 1:K
        SSE_norm(:, kIndex) = sum((pcaData_norm - C_norm(kIndex, :)).^2, 2);
    end
    
    [SSE_norm_min, sortResult.clusterIdx] = min(SSE_norm, [], 2);
    sortResult.noiseClusterIdx = sortResult.clusterIdx;

    p = 0.05; % prominence
    cv = chi2inv(1 - p, size(pcaData, 2)); % critical value
    sortResult.clusterIdx(SSE_norm_min > cv) = 0;
    sortResult.noiseClusterIdx(SSE_norm_min <= cv) = 0;
    sortResult.templates = genTemplates(sortResult);

    sortResult.clusterCenter = zeros(K, size(C_norm, 2));

    for kIndex = 1:K
        sortResult.clusterCenter(kIndex, :) = mean(pcaData(sortResult.clusterIdx == kIndex, :), 1);
    end

    disp('Matching Done.');
    return;
end