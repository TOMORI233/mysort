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

    SSEs = [];

    for index = 1:length(KmeansOpts.KArray)
        % MATLAB - kmeans
        % [~, ~, sumd] = kmeans(Data, KmeansOpts.KArray(index), 'MaxIter', 50, 'Distance', 'sqeuclidean', 'Replicates', 5, 'Options', statset('Display', 'final'));
        [~, ~, sumd] = mKmeans(Data, KmeansOpts.KArray(index), KmeansOpts);
        SSEs = [SSEs; sum(sumd)];
    end

    K = 7;

    return;
end
