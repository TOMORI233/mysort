function [idx, SSEs, gaps, K, pcaData, C, noiseIdx] = spikeSorting(Waveforms, CVCRThreshold, KselectionMethod, KmeansOpts)
    % Description: use PCA and K-means for single channel spike sorting
    % Input:
    %     Waveforms: each row is a spike waveform and each column is a time sample point
    %     CVCRThreshold: cumulative variance contribution rate threshold for principal components selection (default: 0.9)
    %     KselectionMethod: method used to find an optimum K value for K-means
    %                       - "elbow": use elbow method
    %                       - "gap": use gap statistic (default)
    %                       - "both": use gap statistic but also return SSE result of elbow method
    %                       - "preview": plot 3-D PCA data and use an input K from user
    %     KmeansOpts: kmeans settings, a struct containing:
    %                 - KArray: possible K values for K-means (default: 1:10)
    %                 - maxIteration: maximum number of iterations (default: 100)
    %                 - maxRepeat: maximum number of times to repeat kmeans (default: 3)
    %                 - plotIterationNum: number of iterations to plot (default: 0)
    %                 - K: user-specified K. If left empty, an optimum K will be calculated and used (default: [])
    % Output:
    %     idx: cluster index of each sample, with 0 as noise
    %     SSEs: by elbow method
    %     gaps: by gap statistic
    %     K: optimum K value for K-means
    %     pcaData: SCORE of PCA result
    %     C: cluster centers
    %     noiseIdx: cluster index of each noise sample, with 0 as non-noise

    warning on;
    narginchk(1, 4);
    addpath(genpath(fileparts(mfilename('fullpath'))));

    run(fullfile(fileparts(mfilename('fullpath')), 'config', 'defaultConfig.m'));
    defaultKmeansOpts = defaultSortOpts.KmeansOpts;

    if nargin < 2
        CVCRThreshold = 0.9;
    end

    if nargin < 3
        KselectionMethod = "gap";
    end

    KmeansOpts = getOrFull(KmeansOpts, defaultKmeansOpts);

    %% PCA
    disp('Performing PCA on Waveforms...');
    % -------------default: use mPCA------------
    % [V, S, k] = mPCA(Waveforms, CVCRThreshold);
    % pcaData = S(:, 1:k);
    % -------------END of mPCA------------------

    % ---------------MATLAB pca-----------------
    [~, SCORE, latent] = pca(Waveforms);
    explained = latent / sum(latent);
    contrib = 0;

    for index = 1:size(explained, 1)
        contrib = contrib + explained(index);

        if contrib >= CVCRThreshold
            pcaData = SCORE(:, 1:index);
            break;
        end

    end
    % -----------END of MATLAB pca-------------

    nSpikes = size(pcaData, 1);
    df = size(pcaData, 2); % degree of freedom

    %% K-means
    % Find an optimum K for K-means
    SSEs = [];
    gaps = [];
    n_tests = 5;

    if isfield(KmeansOpts, "K") && ~isempty(KmeansOpts.K)
        disp('Using user-speciified K for clustering.');
        K = KmeansOpts.K;
    else
        disp('Searching for an optimum K for clustering...');

        if strcmpi(KselectionMethod, "elbow")
            % elbow method
            [K, SSEs] = elbow_method(pcaData, KmeansOpts);
        elseif strcmpi(KselectionMethod, "gap")
            % Gap statistic
            KmeansOpts.KArray = min([nSpikes min(KmeansOpts.KArray)]):min([nSpikes max(KmeansOpts.KArray)]);
            [K, gaps] = gap_statistic(pcaData, KmeansOpts.KArray, n_tests);
        elseif strcmpi(KselectionMethod, "both")
            % Calculate both SSE and gaps but use K of maximum gaps
            KmeansOpts.KArray = min([nSpikes min(KmeansOpts.KArray)]):min([nSpikes max(KmeansOpts.KArray)]);
            [K, gaps] = gap_statistic(pcaData, KmeansOpts.KArray, n_tests);
            [~, SSEs] = elbow_method(pcaData, KmeansOpts);
        elseif strcmpi(KselectionMethod, "preview")
            % Preview 3-D PCA space and use a user-specified K
            Fig = figure;
            % set(Fig, "outerposition", get(0, "screensize"));
            maximizeFig(Fig);

            if size(pcaData, 2) >= 3
                plot3(pcaData(:, 1), pcaData(:, 2), pcaData(:, 3), 'k.', 'MarkerSize', 12, 'DisplayName', 'Raw PCA data');
                legend;
                title('Preview 3-D PCA data');
                xlabel('PC-1'); ylabel('PC-2'); zlabel('PC-3');
            elseif size(pcaData, 2) == 2
                warning('PCA dimensions = 2. Please check your data and waveform length.');
                plot(pcaData(:, 1), pcaData(:, 2), 'k.', 'MarkerSize', 12, 'DisplayName', 'Raw PCA data');
                legend;
                title('Preview 2-D PCA data');
                xlabel('PC-1'); ylabel('PC-2');
            else
                warning('PCA dimensions = 1. Please check your data and waveform length.');
                plot(pcaData(:, 1), 'k.', 'MarkerSize', 12, 'DisplayName', 'Raw PCA data');
                legend;
                title('Preview 1-D PCA data');
                xlabel('PC-1');
            end

            drawnow;
            K = validateInput_beta(["non-negative", "integer"], 'Input a K value for K-means (zero for auto-searching): ');

            if K == 0
                % elbow method
                disp('Using elbow method...');
                [K, SSEs] = elbow_method(pcaData, KmeansOpts);
                % Gap statistic
                % disp('Using gap statistic...');
                % KmeansOpts.KArray = min([nSpikes, min(KmeansOpts.KArray)]):min([nSpikes, max(KmeansOpts.KArray)]);
                % [K, gaps] = gap_statistic(pcaData, KmeansOpts.KArray, n_tests);
            end

            try
                close(Fig);
            catch e
                warning(e);
            end

        end

    end

    if isempty(K)
        K = 1;
    end

    disp('Performing K-means on PCA data ...');
    % default: use mKmeans
    % [idx, C, ~] = mKmeans(pcaData, K, KmeansOpts);
    % MATLAB - kmeans
    [idx, C, ~] = kmeans(pcaData, K, 'MaxIter', KmeansOpts.maxIteration, 'Distance', 'sqeuclidean', 'Replicates', KmeansOpts.maxRepeat, 'Options', statset('Display', 'final'));

    % Exclude possible noise of each cluster
    temp = normalize([pcaData; mean(pcaData, 1)], 1);
    pcaData_norm = temp(1:end - 1, :);
    C_norm = temp(end, :);
    SSE_norm = sum((pcaData_norm - C_norm).^2, 2);
    noiseIdx = idx;
    cv = chi2inv(1 - KmeansOpts.p_noise, df); % critical value
    idx(SSE_norm > cv) = 0; % set normalized SSE > critical value of chi(df) as noise
    noiseIdx(SSE_norm <= cv) = 0;

    return;
end
