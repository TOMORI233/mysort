function selectedIdx = recluster(sortResult, PCShown, colors)
    % Description: plot raster in PCA space (ignore noise cluster), dimensions specified by PCShown
    % Input:
    %     sortResult: struct generated by mysort
    %     PCShown: a vector containing PC dimensions to be shown, length of which is 2(default: [1 2]).
    %     colors: cell array of colors for waveform templates, each specified as
    %             an RGB triplet, a hexadecimal color code, a color name,
    %             or a short name. Same with wave plot color setting (RECOMMENDED).
    % Output:
    %     selectedIdx: selected spike index
    % Example:
    %     sortResult = mysort(data);
    %     v = input("Please input a cluster number for reclustering: ");
    %     % 1 - Exclude noise
    %     selectedIdx = recluster(sortResult, [1, 2]);
    %     sortResult.clusterIdx(selectedIdx & ~logical(sortResult.noiseClusterIdx)) = v;
    %     % 2 - Multi-dimension selection
    %     selectedIdx1 = recluster(sortResult, [1, 2]);
    %     selectedIdx2 = recluster(sortResult, [2, 3]);
    %     sortResult.clusterIdx(selectedIdx1 & selectedIdx2 & ~logical(sortResult.noiseClusterIdx)) = v;

    narginchk(1, 3);

    if nargin < 2
        PCShown = [1, 2];
    end

    if nargin < 3
        colors = generateColorGrad(12, 'rgb', 'red', [1, 4, 7, 10], 'green', [2, 5, 8, 11], 'blue', [3, 6, 9, 12]);
    end

    PCx = PCShown(1);
    PCy = PCShown(2);

    Fig = figure;
    maximizeFig(Fig);
    mAxe = mSubplot(Fig, 1, 1, 1, 1, [0, 0, 0, 0], [0.1, 0.1, 0.1, 0.1]);

    cm = uicontextmenu(Fig);
    mAxe.ContextMenu = cm;

    m1 = uimenu(cm, 'Text', 'Place Polygon');
    set(m1, "MenuSelectedFcn", {@menuPlaceFcn, Fig});

    mView = uimenu(cm, 'Text', 'View');
    m2 = uimenu(mView, 'Text', 'View Waveforms');
    set(m2, "MenuSelectedFcn", {@menuViewFcn, Fig, 1});
    set(m2, "Enable", "off");
    m3 = uimenu(mView, 'Text', 'View PCA');
    set(m3, "MenuSelectedFcn", {@menuViewFcn, Fig, 2});
    set(m3, "Enable", "off");
    m4 = uimenu(mView, 'Text', 'View Amplitude');
    set(m4, "MenuSelectedFcn", {@menuViewFcn, Fig, 3});
    set(m4, "Enable", "off");
    m5 = uimenu(mView, 'Text', 'View SSE');
    set(m5, "MenuSelectedFcn", {@menuViewFcn, Fig, 4});
    set(m5, "Enable", "off");

    m6 = uimenu(cm, 'Text', 'Change PC');
    set(m6, "MenuSelectedFcn", {@menuChangePCFcn, Fig});

    m7 = uimenu(cm, 'Text', 'Confirm');
    set(m7, "MenuSelectedFcn", {@menuConfirmFcn, Fig});

    DTO.sortResult = sortResult;
    DTO.PCx = PCx;
    DTO.PCy = PCy;
    DTO.colors = colors;
    set(Fig, "UserData", DTO);

    for index = 1:sortResult.K
        idx = find(sortResult.clusterIdx == index);
        x = sortResult.pcaData(idx, PCx);

        if isempty(x)
            continue;
        end

        y = sortResult.pcaData(idx, PCy);
        cx = sortResult.clusterCenter(index, PCx);
        cy = sortResult.clusterCenter(index, PCy);

        colorsAll = repmat(reshape(colors, [length(colors), 1]), ceil(sortResult.K / length(colors)) * length(colors), 1);
        plot(x, y, '.', 'MarkerSize', 12, 'Color', colorsAll{index}, 'DisplayName', ['cluster ' num2str(index)]); hold on;
        h = plot(cx, cy, 'kx', 'LineWidth', 1.2, 'MarkerSize', 15);
        set(get(get(h, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off');
    end

    % Noise
    idx = find(sortResult.clusterIdx == 0);
    nx = sortResult.pcaData(idx, PCx);
    ny = sortResult.pcaData(idx, PCy);
    plot(nx, ny, 'ko', 'DisplayName', 'Noise');

    % Origin data
    % plot(sortResult.pcaData(:, PCx), sortResult.pcaData(:, PCy), 'k.', 'MarkerSize', 12, 'DisplayName', 'Origin');

    legend;
    title(['Channel: ', num2str(sortResult.chanIdx), ' | nSamples = ', num2str(size(sortResult.wave, 1))]);
    xlabel(['PC-' num2str(PCx)]);
    ylabel(['PC-' num2str(PCy)]);

    % Wait for user
    uiwait(Fig);

    try
        DTO = get(Fig, "UserData");
        PCx = DTO.PCx;
        PCy = DTO.PCy;
        selectedIdx = inpolygon(sortResult.pcaData(:, PCx), sortResult.pcaData(:, PCy), DTO.xv, DTO.yv);
    catch
        selectedIdx = [];
    end

    return;
end

%% MenuSelectedFcn
function menuPlaceFcn(~, ~, Fig)
    mAxe = gca;
    menus = mAxe.ContextMenu.Children;
    menus = [menus; menus(3).Children];
    set(menus, "Enable", "off");
    DTO = get(Fig, "UserData");
    delete(getOr(DTO, "lines"));
    [xv, yv, lines] = genPolygon(gca);
    DTO.xv = xv;
    DTO.yv = yv;
    DTO.lines = lines;
    set(Fig, "UserData", DTO);
    set(menus, "Enable", "on");
end

function menuConfirmFcn(~, ~, Fig)
    uiresume(Fig);
end

function menuViewFcn(~, ~, Fig, opt)
    DTO = get(Fig, "UserData");
    sortResult = DTO.sortResult;
    selectedIdx = inpolygon(sortResult.pcaData(:, DTO.PCx), sortResult.pcaData(:, DTO.PCy), DTO.xv, DTO.yv);
    sortResult.clusterIdx(selectedIdx & ~logical(sortResult.noiseClusterIdx)) = sortResult.K + 1;
    sortResult.K = sortResult.K + 1;
    [sortResult.templates, sortResult.clusterCenter] = genTemplates(sortResult);

    switch opt
        case 1
            plotWave(sortResult);
        case 2
            plotPCA(sortResult, [1 2 3]);
        case 3
            plotSpikeAmp(sortResult);
        case 4
            plotNormalizedSSE(sortResult);
    end
end

function menuChangePCFcn(~, ~, Fig)
    DTO = get(Fig, "UserData");
    sortResult = DTO.sortResult;
    colors = DTO.colors;
    [PCx, PCy] = pcInput(DTO.PCx, DTO.PCy);
    DTO.PCx = PCx;
    DTO.PCy = PCy;
    set(Fig, "UserData", DTO);
    cla;

    for index = 1:sortResult.K
        idx = find(sortResult.clusterIdx == index);
        x = sortResult.pcaData(idx, PCx);

        if isempty(x)
            continue;
        end

        y = sortResult.pcaData(idx, PCy);
        cx = sortResult.clusterCenter(index, PCx);
        cy = sortResult.clusterCenter(index, PCy);

        colorsAll = repmat(reshape(colors, [length(colors), 1]), ceil(sortResult.K / length(colors)) * length(colors), 1);
        plot(x, y, '.', 'MarkerSize', 12, 'Color', colorsAll{index}, 'DisplayName', ['cluster ' num2str(index)]); hold on;
        h = plot(cx, cy, 'kx', 'LineWidth', 1.2, 'MarkerSize', 15);
        set(get(get(h, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off');
    end

    % Noise
    idx = find(sortResult.clusterIdx == 0);
    nx = sortResult.pcaData(idx, PCx);
    ny = sortResult.pcaData(idx, PCy);
    plot(nx, ny, 'ko', 'DisplayName', 'Noise');

    % Origin data
    % plot(sortResult.pcaData(:, PCx), sortResult.pcaData(:, PCy), 'k.', 'MarkerSize', 12, 'DisplayName', 'Origin');

    legend;
    title(['Channel: ', num2str(sortResult.chanIdx), ' | nSamples = ', num2str(size(sortResult.wave, 1))]);
    xlabel(['PC-' num2str(PCx)]);
    ylabel(['PC-' num2str(PCy)]);
end
