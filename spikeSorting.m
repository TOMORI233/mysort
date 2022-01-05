function [idx, SSEs, gaps, K, pcaData, C] = spikeSorting(Data, CVCRThreshold, KselectionMethod, KmeansOpts)
    % Description: Using PCA and K-means for spike sorting
    % Input:
    %     Data: samples along row, each column represents a feature
    %     CVCRThreshold: cumulative variance contribution rate threshold for principal components selection
    %     KselectionMethod: "elbow" or "gap", method used to find an optimum K value for K-means
    %                       - "elbow": use elbow method
    %                       - "gap": use gap statistic
    %     KmeansOpts: kmeans settings, a struct containing:
    %                 - KArray: possible K values for K-means
    %                 - maxIteration: maximum number of iterations
    %                 - maxRepeat: maximum number of times to repeat kmeans
    %                 - plotIterationNum: number of iterations to plot
    %                 - K: user-specified K. If left empty, an optimum K will be calculated and used
    % Output:
    %     idx: cluster index of each sample, with 0 as noise
    %     SSEs: by elbow method
    %     gaps: by gap statistic
    %     K: optimum K value for K-means
    %     pcaData: SCORE of PCA result
    %     C: cluster centers

    %% PCA
    [V, S, k] = mPCA(Data, CVCRThreshold);
    pcaData = S(:, 1:k);

    % MATLAB - pca
    % [coeff, SCORE, latent] = pca(Data);
    % explained = latent / sum(latent);
    % contrib = 0;
    % for index = 1:size(explained, 1)
    %     contrib = contrib + explained(index);
    %     if contrib >= CVCRThreshold
    %         pcaData = SCORE(:, 1:index);
    %         break;
    %     end
    % end

    %% K-means
    % Find an optimum K for K-means
    if isfield(KmeansOpts, "K")
        K = KmeansOpts.K;
        SSEs = [];
        gaps = [];
    else

        if strcmp(KselectionMethod, "elbow")
            % elbow method
            [K, SSEs] = elbow_method(pcaData, KmeansOpts);
            % Gap statistic
            gaps = [];
        elseif strcmp(KselectionMethod, "gap")
            % Gap statistic
            n_tests = 5;
            KmeansOpts.KArray = min([size(pcaData, 1) min(KmeansOpts.KArray)]):min([size(pcaData, 1) max(KmeansOpts.KArray)]);
            [K, gaps] = gap_statistic(pcaData, KmeansOpts.KArray, n_tests);
            % elbow method
            SSEs = [];
        end

    end

    if isempty(K)
        K = 1;
    end

    % MATLAB - kmeans
    % [idx, C, ~] = kmeans(pcaData, K, 'MaxIter', KmeansOpts.maxIteration, 'Distance', 'sqeuclidean', 'Replicates', KmeansOpts.maxRepeat, 'Options', statset('Display', 'final'));
    [idx, C, ~] = mKmeans(pcaData, K, KmeansOpts);

    % Exclude noise
    distance = [];

    for index = 1:size(pcaData, 1)
        distance = [distance; norm(pcaData(index, :) - C(idx(index), :))];
    end

    meanDist = mean(distance);
    stdDist = std(distance);
    idx(distance > meanDist + 3 * stdDist) = 0;

    return;
end
