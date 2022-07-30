function [templates, clusterCenter] = genTemplates(result)
    % Description: compute mean value of waveforms and pca data of each cluster as templates
    % Input: 
    %     result: mysort result struct
    % Output:
    %     templates: waveform template of each cluster
    %     clusterCenter: mean pca data of each cluster

    templates = zeros(result.K, size(result.wave, 2));
    clusterCenter = zeros(result.K, size(result.pcaData, 2));

    for cIndex = 1:result.K
        idx = find(result.clusterIdx == cIndex);
        waveforms = result.wave(idx, :);
        pcaData = result.pcaData(idx, :);

        if ~isempty(idx)
            templates(cIndex, :) = mean(waveforms);
            clusterCenter(cIndex, :) = mean(pcaData);
        end

    end

    return;
end
