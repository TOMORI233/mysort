function MSE = calMSE(Waveforms, templates)
    nSpikes = size(Waveforms, 1);
    [nTemplates, tLen] = size(templates);
    scaleFactor = 1e6;

    MSE = zeros(nSpikes, nTemplates);

    % Sum of squared differences, the smaller the more similar
    for tIndex = 1:nTemplates
        MSE(:, tIndex) = sum((Waveforms * scaleFactor - templates(tIndex, :) * scaleFactor).^2, 2) / tLen;
    end

    return;
end