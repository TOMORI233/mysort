function templates = genTemplates(result)
    templates = zeros(result.K, size(result.wave, 2));

    for cIndex = 1:result.K
        waveforms = result.wave(result.clusterIdx == cIndex, :);

        if ~isempty(waveforms)
            templates(cIndex, :) = mean(waveforms);
        end

    end

    return;
end
