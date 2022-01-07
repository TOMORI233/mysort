function [idx, SSEs, gaps, K, pcaData, C] = spikeSorting(wave, CVCRThreshold, KselectionMethod, KmeansOpts)
    % Description: use PCA and K-means for single channel spike sorting
    % Input:
    %     wave: samples along row, each column represents a feature
    %     CVCRThreshold: cumulative variance contribution rate threshold for principal components selection
    %     KselectionMethod: "elbow" or "gap", method used to find an optimum K value for K-means
    %                       - "elbow": use elbow method
    %                       - "gap": use gap statistic
    %                       - "both": use gap statistic but also return SSE result of elbow method
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
    % default: use mPCA
    % [V, S, k] = mPCA(wave, CVCRThreshold);
    % pcaData = S(:, 1:k);

    % MATLAB - pca
    [coeff, SCORE, latent] = pca(wave);
    explained = latent / sum(latent);
    contrib = 0;
    for index = 1:size(explained, 1)
        contrib = contrib + explained(index);
        if contrib >= CVCRThreshold
            pcaData = SCORE(:, 1:index);
            break;
        end
    end

    %% K-means
    % Find an optimum K for K-means
    if isfield(KmeansOpts, "K") && ~isempty(KmeansOpts.K)
        K = KmeansOpts.K;
        SSEs = [];
        gaps = [];
    else

        if strcmp(KselectionMethod, "elbow")
            % elbow method
            [K, SSEs] = elbow_method(pcaData, KmeansOpts);
            gaps = [];
        elseif strcmp(KselectionMethod, "gap")
            % Gap statistic
            n_tests = 5;
            KmeansOpts.KArray = min([size(pcaData, 1) min(KmeansOpts.KArray)]):min([size(pcaData, 1) max(KmeansOpts.KArray)]);
            [K, gaps] = gap_statistic(pcaData, KmeansOpts.KArray, n_tests);
            SSEs = [];
        elseif strcmp(KselectionMethod, "both")
            n_tests = 5;
            KmeansOpts.KArray = min([size(pcaData, 1) min(KmeansOpts.KArray)]):min([size(pcaData, 1) max(KmeansOpts.KArray)]);
            [K, gaps] = gap_statistic(pcaData, KmeansOpts.KArray, n_tests);
            [~, SSEs] = elbow_method(pcaData, KmeansOpts);
        end

    end

    if isempty(K)
        K = 1;
    end

    % default: use mKmeans
    % [idx, C, ~] = mKmeans(pcaData, K, KmeansOpts);
    % MATLAB - kmeans
    [idx, C, ~] = kmeans(pcaData, K, 'MaxIter', KmeansOpts.maxIteration, 'Distance', 'sqeuclidean', 'Replicates', KmeansOpts.maxRepeat, 'Options', statset('Display', 'final'));

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
