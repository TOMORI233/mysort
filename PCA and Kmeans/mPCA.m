function [V, SCORE, k] = mPCA(Data, CVCRThreshold)
    % Description: principal component analysis
    % Input:
    %     Data: samples along row, each column represents a feature
    %     CVCRThreshold: cumulative variance contribution rate threshold for principal components selection
    % Output:
    %     V: eigenvector matrix of covariance matrix of Data
    %     SCORE: SCORE of PCA
    %     k: the number of principal components when CVCR > CVCRThreshold
    % Example:
    %     [~, SCORE, k] = mPCA(Data);
    %     pcaData = SCORE(:, 1:k);

    narginchk(1, 2);

    if nargin < 2
        CVCRThreshold = 0.9;
    end

    % samples along rows
    [row, col] = size(Data);

    % zero mean
    Data = (Data - repmat(mean(Data), row, 1)) ./ repmat(std(Data), row, 1);
    Data(isnan(Data)) = 0; % trans NaN into 0

    % 计算协方差矩阵R, R的特征向量矩阵V, 特征值矩阵D, 特征值从大到小排列构成的向量E
    R = cov(Data); % covariance matrix of Data
    [V, D] = eigs(R); % V: eigenvector matrix of R; D: eigenvalue matrix of R
    E = diag(D); % E: eigenvalue vector

    % SCORE
    SCORE = Data * V;

    % 取主成分的前k个使得累计贡献率大于设定的阈值, 如90%
    CVCR = 0;

    for index = 1:col
        CVCR = CVCR + E(index) / sum(E);

        if CVCR >= CVCRThreshold
            k = index;
            break;
        end

    end

    return;
end
