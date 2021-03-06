function Figs = plotSSEorGap(result, visibilityOpt)
    % Description: plot K - Sum of SSE and K - Gaps
    % Input:
    %     result: struct generated by mysort
    %     visibilityOpt: figure visibility, "on"(default) or "off"
    % Output:
    %     Figs: K value versus SSE/Gap figures of all channels

    narginchk(1, 2);

    if nargin == 1
        visibilityOpt = "on";
    end

    for eIndex = 1:length(result)
        Figs(eIndex) = figure;
        % set(Fig, "outerposition", get(0, "screensize"));
        maximizeFig(Figs);
        set(Figs, "Visible", visibilityOpt);

        x = min([size(result(eIndex).pcaData, 1) min(result(eIndex).KArray)]):min([size(result(eIndex).pcaData, 1) max(result(eIndex).KArray)]);

        try
            yyaxis left
            plot(x, result(eIndex).gaps, 'b-o', 'LineWidth', 2, 'DisplayName', 'Gap');
            ylabel('Gaps');
        catch exception1
            disp('Gaps data is empty.');
        end

        try
            yyaxis right
            plot(x, result(eIndex).SSEs, 'r-o', 'LineWidth', 2, 'DisplayName', 'SSE');
            ylabel('Sum of SSE');
        catch exception2
            disp('SSEs data is empty.');
        end

        if exist("exception1", "var") && exist("exception2", "var")
            disp('K is user-specified for sorting this channel');
            close(Figs);
            continue;
        end

        legend;
        title(['Channel: ' num2str(result(eIndex).chanIdx) ' | nSamples = ' num2str(size(result(eIndex).wave, 1)) ' | optimum K is ' num2str(result(eIndex).K)]);
        xlabel('K value');
        grid on;
    end

    return;
end
