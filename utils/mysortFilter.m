function datr = mysortFilter(data, fs)
    % filter single-channel data

    [a, b] = size(data);

    % convert data into column vector
    if a > b % channels along columns
        data = data(:, 1);
    else % channels along rows
        data = data(1, :)';
    end
    
    % set up the parameters of the filter
    fhp = 300; % Hz
    [b1, a1] = butter(3, fhp / fs * 2, 'high'); % the default is to only do high-pass filtering at 150Hz
    
    % subtract the mean from each channel
    data = data - mean(data, 1); % subtract mean of each channel
    
    % filter data with a zero-phase digital filter
    datr = filtfilt(b1, a1, data);

    if a < b
        datr = datr';
    end

    return;
end