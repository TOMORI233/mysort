function [K, SSEs] = elbow_method(Data, KmeansOpts)
    % Description: elbow method
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

    SSEs = zeros(length(KmeansOpts.KArray), 1);

    for index = 1:length(KmeansOpts.KArray)
        % MATLAB - kmeans
        [~, ~, sumd] = kmeans(Data, KmeansOpts.KArray(index), 'MaxIter', 100, 'Distance', 'sqeuclidean', 'Replicates', 2);
        % [~, ~, sumd] = mKmeans(Data, KmeansOpts.KArray(index), KmeansOpts);
        SSEs(index) = sum(sumd);
    end

    Fig = figure;
    plot(KmeansOpts.KArray, SSEs, 'b.-', 'MarkerSize', 10);
    xlabel('K value');
    ylabel('SSE');
    K = input('Input a K value (positive integer): ');

    try
        close(Fig);
    end

    return;
end
