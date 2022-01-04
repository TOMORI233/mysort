function [idx, C, sumd] = mKmeans(pcaData, K, KmeansOpts)
    % Description: kmeans
    % Input:
    %     pcaData: Data processed by PCA
    %     K: number of clusters
    %     KmeansOpts: kmeans settings, a struct containing:
    %                 - KArray: possible K values for K-means
    %                 - maxIteration: maximum number of iterations
    %                 - maxRepeat: maximum number of times to repeat kmeans
    %                 - plotIterationNum: number of iterations to plot
    % Output:
    %     idx: array of cluster index of each sample
    %     C: cluster centers
    %     sumd: sum of inner Euclidean distance of each cluster

    [row, col] = size(pcaData); % row is number of samples, col is pca dimension
    idx = zeros(col, 1); % cluster index for all data
    C = zeros(K, col); % cluster center

    % generate random cluster center
    for index = 1:K
        C(index, :) = pcaData(randi(row, 1), :);
    end

    nRepeat = 0;
    nIteration = 0;

    % repeat k-means until converging or reaching max repeat times
    while nRepeat < KmeansOpts.maxRepeat

        % iterate until converging or reaching max iteration times
        while nIteration < KmeansOpts.maxIteration
            nIteration = nIteration + 1;
            distance = zeros(K, 1); % sum of distance to cluster center
            cIdx = zeros(K, 1); % cluster indexes array
            CNew = zeros(K, col); % new cluster center

            for rIndex = 1:row

                % cal Euclidean distance from this point to each cluster center
                for kIndex = 1:K
                    distance(kIndex) = norm(pcaData(rIndex, :) - C(kIndex, :));
                end

                [~, index] = min(distance); % find the nearest cluster index to this point
                idx(rIndex) = index; % classify this point into cluster (n = rIndex)
            end

            % count how many clusters reach convergence condition
            nK = 0;

            % update cluster center
            for kIndex = 1:K

                for rIndex = 1:row

                    if idx(rIndex) == kIndex
                        CNew(kIndex, :) = CNew(kIndex, :) + pcaData(rIndex, :);
                        cIdx(kIndex) = cIdx(kIndex) + 1;
                    end

                end

                % update center of each cluster
                CNew(kIndex, :) = CNew(kIndex, :) / cIdx(kIndex);

                % convergence condition: for each cluster center update, relative center shift < 0.1
                if norm(CNew(kIndex, :) - C(kIndex, :)) < 0.1
                    nK = nK + 1;
                end

            end

            % convergence condition
            if nK == K
                break;
            else
                C = CNew; % update cluster center
            end

            % plot iteration process
            if nIteration <= KmeansOpts.plotIterationNum
                figure;

                for index = 1:K
                    plot(pcaData(idx == index, 1), pcaData(idx == index, 2), '.', 'DisplayName', ['cluster ' num2str(index)]);
                    hold on;
                end

                legend;

                for index = 1:K
                    h = plot(C(index, 1), C(index, 2), 'kx', 'LineWidth', 1.2);
                    set(get(get(h, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off');
                    hold on;
                end

                hold off;
                title(['K = ' num2str(K) ', iteration: ' num2str(nIteration)]);
                drawnow;
            end

        end

        % cal sum of inner Euclidean distance of each cluster
        sumd = 0;

        for kIndex = 1:K
            sumd = sumd + norm(pcaData(idx == kIndex, :) - C(kIndex, :))^2;
        end

        % display msg
        if nK == K
            % disp(['K = ' num2str(K) ', 迭代次数: ' num2str(nIteration)]);
            break;
        else
            % disp(['K = ' num2str(K) ', 迭代次数: ' num2str(nIteration) ', 未收敛']);
            nRepeat = nRepeat + 1;
        end

    end

    return;
end
