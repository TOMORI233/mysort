function [waveFigs, templateFigs] = plotWave(varargin)
    % plotWave(result)
    % plotWave(waveforms, clusterIdx)
    % plotWave(..., N)
    % plotWave(..., "visible", visibilityOpt, "colors", colors)
    % [waveFigs, templateFigs] = plotWave(...)
    %
    % Description: plot waves of each cluster, with cluster 0 as noise
    % Input:
    %     1. result: struct generated by mysort
    %     2. waveforms: spike waveforms specified as [sample, waveData] (one sample = one spike)
    %        clusterIdx: a vector of cluster index for each spike
    %     N: number of waves to plot (default: 200)
    %     visibilityOpt: figure visibility, "on"(default) or "off"
    %     colors: cell array of colors for waveform templates, each specified as
    %             an RGB triplet, a hexadecimal color code, a color name,
    %             or a short name. Same with PCA plot color setting (RECOMMENDED).
    % Output: 
    %     waveFigs: figure, plot former [N] waveforms of each cluster
    %     templateFigs: figure, waveform template of each cluster

    if isstruct(varargin{1})
        result = varargin{1};
        varargin(1) = [];
    else
        result.wave = varargin{1};
        result.clusterIdx = varargin{2};
        result.chanIdx = 1;
        varargin(1:2) = [];
    end

    mIp = inputParser;
    mIp.addRequired("result", @(x) validatestruct(x, "clusterIdx", @(y) validateattributes(y, 'numeric', {'vector'}), ...
                                                     "wave", @(y) validateattributes(y, 'numeric', {'2d'}), ...
                                                     "chanIdx", @(y) validateattributes(y, 'numeric', {'scalar', 'positive', 'integer'})));
    mIp.addOptional("N", 200, @(x) validateattributes(x, 'numeric', {'scalar', 'positive', 'integer'}));
    mIp.addParameter("visible", "on", @(x) any(validatestring(x, {'on', 'off'})));
    mIp.addParameter("colors", generateColorGrad(12, 'rgb', 'red', [1, 4, 7, 10], 'green', [2, 5, 8, 11], 'blue', [3, 6, 9, 12]), ...
                     @(x) cellfun(@(y) validateattributes(y, 'numeric', {'numel', 3, '>=', 0, '<=', 1}), x));
    mIp.parse(result, varargin{:});

    visibilityOpt = mIp.Results.visible;
    colors = mIp.Results.colors;
    N = mIp.Results.N;

    for eIndex = 1:length(result)

        if ~isempty(result(eIndex).clusterIdx)
            waveFigs(eIndex) = figure;
            % set(Fig, "outerposition", get(0, "screensize"));
            maximizeFig(waveFigs(eIndex));
            set(waveFigs(eIndex), "Visible", visibilityOpt);

            plotCol = 2;

            result(eIndex).templates = getOr(result(eIndex), "templates", genTemplates(result(eIndex)));
            templates = [mean(result(eIndex).wave(result(eIndex).clusterIdx == 0, :), 1); genTemplates(result(eIndex))];
            Ks = unique(result(eIndex).clusterIdx);
            Ks(Ks == 0) = [];
            Ks = [0; Ks];

            % Waveforms of each cluster
            for kIndex = 1:length(Ks)
                plotData = result(eIndex).wave(result(eIndex).clusterIdx == Ks(kIndex), :);

                if ~isempty(plotData)
                    stdValue = std(plotData, 0, 1);

                    mSubplot(waveFigs(eIndex), ceil(length(Ks) / plotCol), plotCol, kIndex, [1, 1], [0.05, 0.05, 0.1, 0.1]);
                    x = 1:size(plotData, 2);
                    xSmooth = linspace(min(x), max(x));
                    yMin = min(result(eIndex).wave(result(eIndex).clusterIdx ~= 0, :), [], "all");
                    yMax = max(result(eIndex).wave(result(eIndex).clusterIdx ~= 0, :), [], "all");

                    for pIndex = 1:min([N, size(plotData, 1)])
                        y = interp1(x, plotData(pIndex, :), xSmooth, 'cubic');
                        h = plot(xSmooth, y, 'b', 'DisplayName', 'Samples');
                        hold on;

                        if pIndex > 1
                            set(get(get(h, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off');
                        end

                    end

                    if size(plotData, 1) > 1
                        y1 = interp1(x, templates(kIndex, :) + stdValue, xSmooth, 'cubic');
                        y2 = interp1(x, templates(kIndex, :) - stdValue, xSmooth, 'cubic');
                        fill([xSmooth fliplr(xSmooth)], [y1 fliplr(y2)], [230, 230, 230] / 255, 'edgealpha', '0', 'facealpha', '.6', 'DisplayName', 'Error bar');
                        plot(xSmooth, interp1(x, templates(kIndex, :), xSmooth, 'cubic'), 'r', 'LineWidth', 2, 'DisplayName', 'Mean');
                    end

                    if Ks(kIndex) > 0
                        title(['Channel: ' num2str(result(eIndex).chanIdx) ' | nSamples = ' num2str(size(plotData, 1)) ' | cluster ' num2str(Ks(kIndex))]);
                        ylim([yMin yMax]);
                    else
                        title(['Channel: ' num2str(result(eIndex).chanIdx) ' | nSamples = ' num2str(size(plotData, 1)) ' | noise']);
                    end

                    legend;
                    % drawnow;
                end

            end

            %Template of each cluster
            templateFigs(eIndex) = figure;
            maximizeFig(templateFigs(eIndex));
            set(templateFigs(eIndex), "Visible", visibilityOpt);
            waveLen = size(templates, 2);
            x = (1:waveLen) - floor(waveLen / 2);
            colorsAll = repmat(reshape(colors, [length(colors), 1]), ceil((length(Ks) - 1) / length(colors)) * length(colors), 1);

            for kIndex = 2:length(Ks)
                plot(x, templates(kIndex, :), "Color", colorsAll{kIndex - 1}, "LineWidth", 2, "DisplayName", ['cluster ', num2str(Ks(kIndex))]); hold on;
            end

            legend;
            grid on;
            xlim([min(x), max(x)]);
            title('Waveform Template');
            set(gca, 'GridAlpha', 0.3);
        end

    end

    return;
end
