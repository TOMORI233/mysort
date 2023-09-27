function PCAFigs = plotPCA(varargin)
    % plotPCA(sortResult)
    % plotPCA(pcaData, clusterIdx)
    % plotPCA(..., PCShown)
    % plotPCA(..., "visible", visibilityOpt, "colors", colors)
    % PCAFigs = plotPCA(...)
    %
    % Description: plot raster in PCA space, dimensions specified by PCShown
    % Input:
    %     1. sortResult: struct generated by mysort
    %     2. pcaData: [sample, pcaData] (one sample = one spike)
    %        clusterIdx: a vector of cluster index for each spike
    %     PCShown: a vector containing PC dimensions to be shown, length of which is either 2 or 3 (default: [1 2])
    %     visibilityOpt: figure visibility, "on"(default) or "off"
    %     colors: cell array of colors for waveform templates, each specified as
    %             an RGB triplet, a hexadecimal color code, a color name,
    %             or a short name. Same with wave plot color setting (RECOMMENDED).
    % Output:
    %     PCAFigs: PCA figures of all channels
    
    if isstruct(varargin{1})
        sortResult = varargin{1};
        varargin(1) = [];
    else
        sortResult.pcaData = varargin{1};
        sortResult.clusterIdx = varargin{2};
        sortResult.chanIdx = 1;
        varargin(1:2) = [];
    end

    mIp = inputParser;
    mIp.addRequired("sortResult", @(x) validatestruct(x, "clusterIdx", @(y) validateattributes(y, 'numeric', {'vector'}), ...
                                                     "pcaData", @(y) validateattributes(y, 'numeric', {'2d'}), ...
                                                     "chanIdx", @(y) validateattributes(y, 'numeric', {'scalar', 'positive', 'integer'})));
    mIp.addOptional("PCShown", [1, 2], @(x) validateattributes(x, 'numeric', {'vector', 'positive', 'integer'}));
    mIp.addParameter("visible", "on", @(x) any(validatestring(x, {'on', 'off'})));
    mIp.addParameter("colors", generateColorGrad(12, 'rgb', 'red', [1, 4, 7, 10], 'green', [2, 5, 8, 11], 'blue', [3, 6, 9, 12]), ...
                     @(x) cellfun(@(y) validateattributes(y, 'numeric', {'numel', 3, '>=', 0, '<=', 1}), x));
    mIp.parse(sortResult, varargin{:});

    visibilityOpt = mIp.Results.visible;
    colors = mIp.Results.colors;
    PCShown = mIp.Results.PCShown;

    PCx = PCShown(1);
    PCy = PCShown(2);

    if length(PCShown) > 2
        PCz = PCShown(3);
    else
        PCz = [];
    end

    for eIndex = 1:length(sortResult)
        PCAFigs(eIndex) = figure;
        % set(Fig, "outerposition", get(0, "screensize"));
        maximizeFig(PCAFigs(eIndex));
        set(PCAFigs(eIndex), "Visible", visibilityOpt);

        mAxe = mSubplot(PCAFigs(eIndex), 1, 1, 1, 1, [0, 0, 0, 0], [0.1, 0.1, 0.1, 0.1]);

        cm = uicontextmenu(PCAFigs(eIndex));
        mAxe.ContextMenu = cm;
    
        m1 = uimenu(cm, 'Text', 'Show & Hide');
        set(m1, "MenuSelectedFcn", {@menuShowAndHideFcn, PCAFigs(eIndex)});

        DTO.sortResult = sortResult(eIndex);
        DTO.PCx = PCx;
        DTO.PCy = PCy;
        DTO.PCz = PCz;
        DTO.colors = colors;
        set(PCAFigs(eIndex), "UserData", DTO);

        Ks = unique(sortResult(eIndex).clusterIdx);
        Ks(Ks == 0) = [];

        for kIndex = 1:length(Ks)
            idx = sortResult(eIndex).clusterIdx == Ks(kIndex);
            x = sortResult(eIndex).pcaData(idx, PCx);
            y = sortResult(eIndex).pcaData(idx, PCy);

            if isempty(x)
                continue;
            end

            colorsAll = repmat(reshape(colors, [length(colors), 1]), ceil(length(Ks) / length(colors)) * length(colors), 1);

            if ~isempty(PCz)
                z = sortResult(eIndex).pcaData(idx, PCz);
                plot3(x, y, z, '.', 'MarkerSize', 12, 'Color', colorsAll{kIndex}, 'DisplayName', ['cluster ' num2str(kIndex)]); hold on;
                h = plot3(mean(x), mean(y), mean(z), 'kh', 'LineWidth', 1.2, 'MarkerSize', 15);
                grid on;
                zlabel(['PC-' num2str(PCz)]);
            else
                plot(x, y, '.', 'MarkerSize', 12, 'Color', colorsAll{kIndex}, 'DisplayName', ['cluster ' num2str(kIndex)]); hold on;
                h = plot(mean(x), mean(y), 'kx', 'LineWidth', 1.2, 'MarkerSize', 15);
            end

            set(get(get(h, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off');
        end

        % Noise
        idx = sortResult(eIndex).clusterIdx == 0;

        if ~isempty(idx)
            nx = sortResult(eIndex).pcaData(idx, PCx);
            ny = sortResult(eIndex).pcaData(idx, PCy);
    
            if ~isempty(PCz)
                nz = sortResult(eIndex).pcaData(idx, PCz);
                plot3(nx, ny, nz, 'ko', 'DisplayName', 'Noise');
            else
                plot(nx, ny, 'ko', 'DisplayName', 'Noise');
            end

        end

        % Origin data
        % plot(sortResult(eIndex).pcaData(:, PCx), sortResult(eIndex).pcaData(:, PCy), 'k.', 'MarkerSize', 12, 'DisplayName', 'Origin');

        legend;
        title(['Channel: ', num2str(sortResult(eIndex).chanIdx), ' | nSamples = ', num2str(size(sortResult(eIndex).pcaData, 1))]);
        xlabel(['PC-' num2str(PCx)]);
        ylabel(['PC-' num2str(PCy)]);
    end

    return;
end

%% menuSelectedFcn
function menuShowAndHideFcn(~, ~, Fig)
    DTO = get(Fig, "UserData");
    sortResult = DTO.sortResult;
    colors = DTO.colors;
    PCx = DTO.PCx;
    PCy = DTO.PCy;
    PCz = DTO.PCz;
    [idxShow, idxHide] = clusterIdxInput(getOr(DTO, "idxShow"), getOr(DTO, "idxHide"));
    Ks = unique(sortResult.clusterIdx);

    if isempty(idxShow)
        idxShow = Ks;
    end

    temp = Ks;
    idxShow = temp(ismember(temp, idxShow) & ~ismember(temp, idxHide));
    idxHide = temp(~ismember(temp, idxShow));
    DTO.idxShow = idxShow;
    DTO.idxHide = idxHide;
    set(Fig, "UserData", DTO);

    cla;
    colorsAll = repmat(reshape(colors, [length(colors), 1]), ceil(sortResult.K / length(colors)) * length(colors), 1);
    Ks(Ks == 0) = [];

    for index = 1:length(Ks)
        idx = sortResult.clusterIdx == Ks(index) & ismember(sortResult.clusterIdx, idxShow);
        x = sortResult.pcaData(idx, PCx);
        y = sortResult.pcaData(idx, PCy);

        if isempty(x)
            continue;
        end

        if ~isempty(PCz)
            z = sortResult.pcaData(idx, PCz);
            plot3(x, y, z, '.', 'MarkerSize', 12, 'Color', colorsAll{index}, 'DisplayName', ['cluster ' num2str(index)]); hold on;
            h = plot3(mean(x), mean(y), mean(z), 'kh', 'LineWidth', 1.2, 'MarkerSize', 15);
            grid on;
            zlabel(['PC-' num2str(PCz)]);
        else
            plot(x, y, '.', 'MarkerSize', 12, 'Color', colorsAll{index}, 'DisplayName', ['cluster ' num2str(index)]); hold on;
            h = plot(mean(x), mean(y), 'kx', 'LineWidth', 1.2, 'MarkerSize', 15);
        end

        set(get(get(h, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off');
    end

    % Noise
    idx = sortResult.clusterIdx == 0 & ~ismember(sortResult.clusterIdx, idxHide);
    nx = sortResult.pcaData(idx, PCx);
    ny = sortResult.pcaData(idx, PCy);

    if ~isempty(nx)

        if ~isempty(PCz)
            nz = sortResult.pcaData(idx, PCz);
            plot3(nx, ny, nz, 'ko', 'DisplayName', 'Noise');
        else
            plot(nx, ny, 'ko', 'DisplayName', 'Noise');
        end

    end

end