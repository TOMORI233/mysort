function SSE_norm = calNormalizedSSE(pcaData, clusterCenter)
    nSpikes = size(pcaData, 1);
    [nCluster, ~] = size(clusterCenter);

    temp = [pcaData; clusterCenter];
    temp = normalize(temp, 1);
    pcaData_norm = temp(1:end - nCluster, :);
    clusterCenter_norm = temp(end - nCluster:end, :);

    SSE_norm = zeros(nSpikes, nCluster);

    % Sum of squared differences, the smaller the more similar
    for index = 1:nCluster
        SSE_norm(:, index) = sum((pcaData_norm - clusterCenter_norm(index, :)).^2, 2);
    end

    return;
end