function [templates, clusterCenter] = genTemplates(sortResult)
    % Description: compute mean value of waveforms and pca data of each cluster as templates
    % Input: 
    %     sortResult: mysort sortResult struct
    % Output:
    %     templates: waveform template of each cluster
    %     clusterCenter: mean pca data of each cluster

    templates = zeros(sortResult.K, size(sortResult.wave, 2));
    clusterCenter = zeros(sortResult.K, size(sortResult.pcaData, 2));

    for cIndex = 1:sortResult.K
        idx = find(sortResult.clusterIdx == cIndex);
        waveforms = sortResult.wave(idx, :);
        pcaData = sortResult.pcaData(idx, :);

        if ~isempty(idx)
            templates(cIndex, :) = mean(waveforms);
            clusterCenter(cIndex, :) = mean(pcaData);
        end

    end

    return;
end
