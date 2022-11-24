function [K, SSEs] = elbow_method(Data, KmeansOpts)
    % Description: elbow method for kmeans
    % Input:
    %     Data: samples along row, each column represents a feature
    %     KmeansOpts: kmeans settings, a struct containing:
    %                 - KArray: possible K values for K-means
    %                 - maxIteration: maximum number of iterations
    %                 - maxRepeat: maximum number of times to repeat kmeans
    %                 - plotIterationNum: number of iterations to plot
    % Output:
    %     K: optimum K value for K-means
    %     SSEs: SSE array for K values appointed by KmeansOpts.KArray

    run("defaultConfig.m");
    KmeansOpts = getOrFull(KmeansOpts, defaultKmeansOpts);
    SSEs = zeros(length(KmeansOpts.KArray), 1);

    parfor index = 1:length(KmeansOpts.KArray)
        % MATLAB - kmeans
        [~, ~, sumd] = kmeans(Data, KmeansOpts.KArray(index), 'MaxIter', KmeansOpts.maxIteration, 'Distance', 'sqeuclidean', 'Replicates', KmeansOpts.maxRepeat);
        % [~, ~, sumd] = mKmeans(Data, KmeansOpts.KArray(index), KmeansOpts);
        SSEs(index) = sum(sumd);
    end

    Fig = figure;
    plot(KmeansOpts.KArray, SSEs, 'b.-', 'MarkerSize', 10);
    xlabel('K value');
    ylabel('SSE');
    drawnow;
    K = validateInput('Input a K value (positive integer): ', @(x) validateattributes(x, "numeric", {'numel', 1, 'positive', 'integer'}));

    try
        close(Fig);
    end

    return;
end
