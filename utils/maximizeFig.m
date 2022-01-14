function maximizeFig(h)
    % Description: maximize the input figure
    % Input:
    %     h: figure object
    % Output: null

    warning off;
    jFrame = get(h, "JavaFrame");
    set(jFrame, "Maximized", 1);

    return;
end