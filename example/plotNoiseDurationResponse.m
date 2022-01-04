function Fig = plotNoiseDurationResponse(cellData, plotSettings, normalizationSettings)
    %% Plot settings
    rasterHeightTotal = plotSettings.rasterHeightTotal;
    rasterWidth = plotSettings.rasterWidth;
    gridAlpha = plotSettings.gridAlpha;
    colors = plotSettings.colors;
    visibilityOpt = plotSettings.visibilityOpt;
    window = cellData.windowParams.window;
    step = cellData.windowParams.step;
    binSize = cellData.windowParams.binSize;
    edge = (window(1) + binSize / 2:step:window(2) - binSize / 2)';

    %% Plotting
    plotData = cellData.data;
    durationCategory = sort(unique([cellData.data.duration], 'sorted'), 'ascend')';
    rasterHeight = rasterHeightTotal / length(durationCategory);

    Fig = figure;
    set(Fig, "visible", visibilityOpt, "outerposition", get(0, "screensize"));
    % Raster
    for durationIndex = 1:length(durationCategory)
        subplot(length(durationCategory), 2, 1);
        rasterData = plotData([plotData.duration] == durationCategory(durationIndex)).raster;

        for trialIndex = 1:size(rasterData, 1)
            plot(rasterData{trialIndex}, ones(length(rasterData{trialIndex}), 1) * trialIndex, 'r.'); hold on;
        end

        set(gca, 'Position', [0.65, 1 - (1 - rasterHeightTotal) / 2 - rasterHeight * durationIndex, rasterWidth, rasterHeight]);

        if durationIndex < length(durationCategory)
            set(gca, 'XTickLabel', []);
        end

        xlabel('Time (ms)');
        xlim(window);
        set(gca, 'XGrid', 'on', 'GridAlpha', gridAlpha);
        ylim([0 trialIndex + 1]);
        set(gca, 'YTick', [1 floor((trialIndex + 1) / 2) trialIndex]);
        ylabel(['Duration ' num2str(durationCategory(durationIndex))], 'Rotation', 0, 'Position', [window(1) - 600, 10]);
    end

    % FR
    subplot(length(durationCategory), 2, 1);

    for durationIndex = 1:length(durationCategory)

        if find(contains(normalizationSettings.plotOption, 'normalize', 'IgnoreCase', true))
            FRData = plotData([plotData.duration] == durationCategory(durationIndex)).normalizedFR;
            ylabel(['Normalized FR (Baseline window [', num2str(normalizationSettings.baselineWindow), '] ms)']);
        else
            FRData = plotData([plotData.duration] == durationCategory(durationIndex)).FR;
            ylabel('Firing Rate (Hz)');
        end

        plot(edge, FRData, 'LineWidth', 2, 'color', colors(durationIndex)); hold on;
    end

    legend([repmat('Duration ', length(durationCategory), 1) num2str(durationCategory)]);
    set(gca, 'Position', [0.1, 0.3, 0.4, 0.5]);
    xlabel('Time (ms)'); xlim(window); set(gca, 'XGrid', 'on', 'GridAlpha', gridAlpha);
    title(['M' num2str(cellData.monkeyNum) 'C' num2str(cellData.cellNum)]);

end
