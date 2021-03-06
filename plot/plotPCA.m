function PCAFigs = plotPCA(result, PCShown, visibilityOpt, colors)
    % Description: plot raster in PCA space, dimensions specified by PCShown
    % Input:
    %     result: struct generated by mysort
    %     PCShown: a vector containing PC dimensions to be shown, length of which is either 2 or 3 (default: [1 2])
    %     visibilityOpt: figure visibility, "on"(default) or "off"
    %     colors: cell array of colors for waveform templates, each specified as
    %             an RGB triplet, a hexadecimal color code, a color name,
    %             or a short name. Same with wave plot color setting (RECOMMENDED).
    % Output:
    %     PCAFigs: PCA figures of all channels

    narginchk(1, 4);

    if nargin < 2
        PCShown = [1, 2];
    end

    if nargin < 3
        visibilityOpt = "on";
    end

    if nargin < 4
        colors = generateColorGrad(12, 'rgb', 'red', [1, 4, 7, 10], 'green', [2, 5, 8, 11], 'blue', [3, 6, 9, 12]);
    end

    PCx = PCShown(1);
    PCy = PCShown(2);

    if length(PCShown) > 2
        PCz = PCShown(3);
    else
        PCz = [];
    end

    for eIndex = 1:length(result)
        PCAFigs(eIndex) = figure;
        % set(Fig, "outerposition", get(0, "screensize"));
        maximizeFig(PCAFigs(eIndex));
        set(PCAFigs(eIndex), "Visible", visibilityOpt);

        mAxe = mSubplot(PCAFigs(eIndex), 1, 1, 1, 1, [0, 0, 0, 0], [0.1, 0.1, 0.1, 0.1]);

        cm = uicontextmenu(PCAFigs(eIndex));
        mAxe.ContextMenu = cm;
    
        m1 = uimenu(cm, 'Text', 'Show & Hide');
        set(m1, "MenuSelectedFcn", {@menuShowAndHideFcn, PCAFigs(eIndex)});

        DTO.result = result(eIndex);
        DTO.PCx = PCx;
        DTO.PCy = PCy;
        DTO.PCz = PCz;
        DTO.colors = colors;
        set(PCAFigs(eIndex), "UserData", DTO);

        for index = 1:result(eIndex).K
            idx = result(eIndex).clusterIdx == index;
            x = result(eIndex).pcaData(idx, PCx);
            y = result(eIndex).pcaData(idx, PCy);

            if isempty(x)
                continue;
            end

            colorsAll = repmat(reshape(colors, [length(colors), 1]), ceil(result(eIndex).K / length(colors)) * length(colors), 1);

            if ~isempty(PCz)
                z = result(eIndex).pcaData(idx, PCz);
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
        idx = result(eIndex).clusterIdx == 0;
        nx = result(eIndex).pcaData(idx, PCx);
        ny = result(eIndex).pcaData(idx, PCy);

        if ~isempty(PCz)
            nz = result(eIndex).pcaData(idx, PCz);
            plot3(nx, ny, nz, 'ko', 'DisplayName', 'Noise');
        else
            plot(nx, ny, 'ko', 'DisplayName', 'Noise');
        end

        % Origin data
        % plot(result(eIndex).pcaData(:, PCx), result(eIndex).pcaData(:, PCy), 'k.', 'MarkerSize', 12, 'DisplayName', 'Origin');

        legend;
        title(['Channel: ', num2str(result(eIndex).chanIdx), ' | nSamples = ', num2str(size(result(eIndex).wave, 1))]);
        xlabel(['PC-' num2str(PCx)]);
        ylabel(['PC-' num2str(PCy)]);
    end

    return;
end

%% menuSelectedFcn
function menuShowAndHideFcn(~, ~, Fig)
    DTO = get(Fig, "UserData");
    result = DTO.result;
    colors = DTO.colors;
    PCx = DTO.PCx;
    PCy = DTO.PCy;
    PCz = DTO.PCz;
    [idxShow, idxHide] = clusterIdxInput(getOr(DTO, "idxShow"), getOr(DTO, "idxHide"));

    if isempty(idxShow)
        idxShow = 0:result.K;
    end

    temp = 0:result.K;
    idxShow = temp(ismember(temp, idxShow) & ~ismember(temp, idxHide));
    idxHide = temp(~ismember(temp, idxShow));
    DTO.idxShow = idxShow;
    DTO.idxHide = idxHide;
    set(Fig, "UserData", DTO);

    cla;
    colorsAll = repmat(reshape(colors, [length(colors), 1]), ceil(result.K / length(colors)) * length(colors), 1);

    for index = 1:result.K
        idx = result.clusterIdx == index & ismember(result.clusterIdx, idxShow);
        x = result.pcaData(idx, PCx);
        y = result.pcaData(idx, PCy);

        if isempty(x)
            continue;
        end

        if ~isempty(PCz)
            z = result.pcaData(idx, PCz);
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
    idx = result.clusterIdx == 0 & ~ismember(result.clusterIdx, idxHide);
    nx = result.pcaData(idx, PCx);
    ny = result.pcaData(idx, PCy);

    if ~isempty(nx)

        if ~isempty(PCz)
            nz = result.pcaData(idx, PCz);
            plot3(nx, ny, nz, 'ko', 'DisplayName', 'Noise');
        else
            plot(nx, ny, 'ko', 'DisplayName', 'Noise');
        end

    end

end