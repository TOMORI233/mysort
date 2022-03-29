function [crossResult, percentage, cv] = calCrossResult(sortResult, p)
    % Description: calculate cross result of SSE of each template on each cluster
    % Input:
    %     sortResult: a struct of mysort sorting result
    %     p: prominence
    % Output:
    %     crossResult: a K*K cell array with clusters along rows and templates along columns
    %     percentage: a K*K double array with clusters along rows and templates along columns.
    %                 It is the percentage of SSE <= critical value.
    %     cv: critical value of a standard chi-square distribution. The data points on each
    %         principal component of all clusters follow a normal distribution with a zero mean.
    %         After being normalized to N(0, 1), the sum of square value of points of each
    %         cluster will follow a standard chi-square distribution. cv is the critical value
    %         corresponding to the standard chi-square distribution at a prominence level of p.

    K = sortResult.K;
    pca_temp = normalize([sortResult.pcaData; sortResult.clusterCenter], 1);
    pcaData_norm = pca_temp(1:end - K, :);
    C_norm = pca_temp(end - K + 1:end, :);
    SSE_norm = zeros(size(pcaData_norm, 1), K);

    for index = 1:K
        SSE_norm(:, index) = sum((pcaData_norm - C_norm(index, :)).^2, 2);
    end

    df = size(C_norm, 2);
    cv = chi2inv(1 - p, df);
    percentage = zeros(K);
    crossResult = cell(K);

    for t1 = 1:K
        % similarity of template t2 on cluster t1
        for t2 = 1:K
            crossResult{t1, t2} = SSE_norm(sortResult.clusterIdx == t1 | (sortResult.clusterIdx == t1 & sortResult.noiseClusterIdx == t1), t2);
            
            if ~isempty(crossResult{t1, t2})
                percentage(t1, t2) = length(find(crossResult{t1, t2} <= cv)) / length(crossResult{t1, t2});
            end
            
        end

    end

    return;
end