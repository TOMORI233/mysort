function AmpFigs = plotSpikeAmp(varargin)
    % plotSpikeAmp(result)
    % plotSpikeAmp(spikeAmp, spikeTimeAll, clusterIdx)
    % plotSpikeAmp(..., "visible", visibilityOpt, "colors", colors)
    % AmpFigs = plotSpikeAmp(...)
    %
    % Description: plot amplitude distribution of each cluster
    % Input:
    %     1. result: struct generated by mysort
    %     2. spikeAmp: a vector of spike amplitudes
    %        spikeTimeAll: a vector of spike time
    %        clusterIdx: a vector of cluster index for each spike
    %     visbilityOpt: "on" or "off"
    %     colors: RGB cell array of color of each cluster
    % Output:
    %     AmpFigs: histogram

    if isstruct(varargin{1})
        result = varargin{1};
        varargin(1) = [];
    else
        result.spikeAmp = varargin{1};
        result.spikeTimeAll = varargin{2};
        result.clusterIdx = varargin{3};
        varargin(1:3) = [];
    end

    mIp = inputParser;
    mIp.addRequired("result", @(x) validatestruct(x, "clusterIdx", @(y) validateattributes(y, 'numeric', {'vector'}), ...
                                                     "spikeAmp", @(y) validateattributes(y, 'numeric', {'vector'}), ...
                                                     "spikeTimeAll", @(y) validateattributes(y, 'numeric', {'vector'})));
    mIp.addParameter("visible", "on", @(x) any(validatestring(x, {'on', 'off'})));
    mIp.addParameter("colors", generateColorGrad(12, 'rgb', 'red', [1, 4, 7, 10], 'green', [2, 5, 8, 11], 'blue', [3, 6, 9, 12]), ...
                     @(x) cellfun(@(y) validateattributes(y, 'numeric', {'numel', 3, '>=', 0, '<=', 1}), x));
    mIp.parse(result, varargin{:});

    visibilityOpt = mIp.Results.visible;
    colors = mIp.Results.colors;

    for eIndex = 1:length(result)
        % Plot
        AmpFigs(eIndex) = figure;
        maximizeFig(AmpFigs(eIndex));
        set(AmpFigs(eIndex), "Visible", visibilityOpt);

        paddings = [0.05, 0.05, 0.05, 0.05];
        mAxe1 = mSubplot(AmpFigs(eIndex), 1, 1, 1, [0.8, 1], "alignment", "center-left", "margin_left", 0, "paddings", paddings);
        mAxe2 = mSubplot(AmpFigs(eIndex), 1, 1, 1, [0.15, 1], "alignment", "center-right", "margin_right", 0, "paddings", paddings);

        cm = uicontextmenu(AmpFigs(eIndex));
        mAxe1.ContextMenu = cm;
        mAxe2.ContextMenu = cm;
    
        m1 = uimenu(cm, 'Text', 'Show & Hide');
        set(m1, "MenuSelectedFcn", {@menuShowAndHideFcn, AmpFigs(eIndex), mAxe1, mAxe2});

        DTO.result = result(eIndex);
        DTO.colors = colors;
        set(AmpFigs(eIndex), "UserData", DTO);

        Ks = unique(result(eIndex).clusterIdx);
        Ks(Ks == 0) = [];
        colorsAll = repmat(reshape(colors, [length(colors), 1]), ceil(length(Ks) / length(colors)) * length(colors), 1);
        spikeAmp = result(eIndex).spikeAmp;

        for kIndex = 1:length(Ks)
            idx = result(eIndex).clusterIdx == Ks(kIndex);

            if isempty(find(idx, 1))
                continue;
            end

            scatter(mAxe1, result(eIndex).spikeTimeAll(idx), spikeAmp(idx), 30, "filled", "MarkerFaceColor", colorsAll{kIndex}, "DisplayName", ['cluster ', num2str(kIndex)]);
            hold(mAxe1, "on");

            edges = linspace(min(spikeAmp(idx)), max(spikeAmp(idx)), 100);
            h = histogram(mAxe2, spikeAmp(idx), "FaceColor", colorsAll{kIndex}, "FaceAlpha", 0.3, "BinEdges", edges);
            set(get(get(h, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off');
            hold(mAxe2, "on");

            f = ksdensity(spikeAmp(idx), edges, 'Function', 'pdf', 'BoundaryCorrection', 'reflection');
            f = mapminmax(f, 0, 1) * max(h.Values);
            plot(mAxe2, edges, f, "Color", colorsAll{kIndex}, "LineWidth", 2, "DisplayName", ['cluster ', num2str(kIndex)]);
        end

        legend(mAxe1, "Location", "best");
        xlabel(mAxe1, "Time");
        ylabel(mAxe1, "Spike amplitude");
        title(mAxe1, "Spike amplitude over time");
        
        legend(mAxe2, "Location", "best");
        xlabel(mAxe2, "Spike amplitude");
        ylabel(mAxe2, "Count");
        xlim(mAxe2, mAxe1.YLim);
        ylim(mAxe2, [0, inf]);
        title(mAxe2, "Spike amplitude distribution");
        mAxe2.View = [90, 90];
        mAxe2.XDir = "reverse";
    end

    return;
end

%% menuSelectedFcn
function menuShowAndHideFcn(~, ~, Fig, mAxe1, mAxe2)
    DTO = get(Fig, "UserData");
    result = DTO.result;
    colors = DTO.colors;
    [idxShow, idxHide] = clusterIdxInput(getOr(DTO, "idxShow"), getOr(DTO, "idxHide"));
    Ks = unique(result.clusterIdx);
    Ks(Ks == 0) = [];

    if isempty(idxShow)
        idxShow = Ks;
    end

    temp = Ks;
    idxShow = temp(ismember(temp, idxShow) & ~ismember(temp, idxHide));
    idxHide = temp(~ismember(temp, idxShow));
    DTO.idxShow = idxShow;
    DTO.idxHide = idxHide;
    set(Fig, "UserData", DTO);
    cla(mAxe1);
    cla(mAxe2);

    colorsAll = repmat(reshape(colors, [length(colors), 1]), ceil(length(Ks) / length(colors)) * length(colors), 1);
    spikeAmp = result.spikeAmp;

    for kIndex = 1:length(Ks)
        idx = result.clusterIdx == Ks(kIndex) & ismember(result.clusterIdx, idxShow);

        if isempty(find(idx, 1))
            continue;
        end

        scatter(mAxe1, result.spikeTimeAll(idx), spikeAmp(idx), 30, "filled", "MarkerFaceColor", colorsAll{kIndex}, "DisplayName", ['cluster ', num2str(kIndex)]);
        hold(mAxe1, "on");
        
        edges = linspace(min(spikeAmp(idx)), max(spikeAmp(idx)), 100);
        h = histogram(mAxe2, spikeAmp(idx), "FaceColor", colorsAll{kIndex}, "FaceAlpha", 0.3, "BinEdges", edges);
        set(get(get(h, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off');
        hold(mAxe2, "on");

        f = ksdensity(spikeAmp(idx), edges, 'Function', 'pdf', 'BoundaryCorrection', 'reflection');
        f = mapminmax(f, 0, 1) * max(h.Values);
        plot(mAxe2, edges, f, "Color", colorsAll{kIndex}, "LineWidth", 2, "DisplayName", ['cluster ', num2str(kIndex)]);
    end

    xlim(mAxe2, mAxe1.YLim);
end