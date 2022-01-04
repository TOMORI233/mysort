function result = NoiseDurationResponseProcess(data, windowParams, normalizationSettings, sortData, cIndex)

    narginchk(3, 5);

    %% Parameter settings
    window = windowParams.window; % ms
    step = windowParams.step; % ms
    binSize = windowParams.binSize; % ms
    edge = (window(1) + binSize / 2:step:window(2) - binSize / 2)'; % ms

    %% Information extraction
    onsetTimeAll = data.epocs.Swep.onset * 1000; % ms
    durationAll = data.epocs.dura.data; % ms

    if nargin == 5
        spikeTimeAll = sortData.spikeTimeAll(sortData.clusterIdx == cIndex) * 1000; % ms
    elseif nargin == 3
        spikeTimeAll = data.snips.eNeu.ts * 1000; % ms
    else
        result = [];
        warning('输入参数数目错误');
        return;
    end

    %% Categorizations
    % By sound onset time and window
    for trialIndex = 1:length(onsetTimeAll)
        trialAll(trialIndex, 1).duration = durationAll(trialIndex);
        trialAll(trialIndex, 1).spike = spikeTimeAll(spikeTimeAll >= onsetTimeAll(trialIndex) + window(1) & spikeTimeAll < onsetTimeAll(trialIndex) + window(2)) - onsetTimeAll(trialIndex);
    end

    % By duration
    durationCategory = sort(unique(durationAll, 'sorted'), 'ascend');

    for durationIndex = 1:length(durationCategory)
        result(durationIndex, 1).duration = durationCategory(durationIndex);
        result(durationIndex, 1).raster = {trialAll([trialAll.duration] == durationCategory(durationIndex), 1).spike}';
        result(durationIndex, 1).FR = mHist(cell2mat(result(durationIndex, 1).raster), edge, binSize) / length(result(durationIndex, 1).raster) / (binSize / 1000);
        result(durationIndex, 1).normalizedFR = NormalizeFR(result(durationIndex, 1), normalizationSettings);
    end

end
