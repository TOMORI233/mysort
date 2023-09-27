%% default sortOpts

% sample rate
% Default fs here has the highest priority. Please try not to specify fs here
% defaultSortOpts.fs = 24414.0625; % Hz

% threshold
% Default th has the highest priority. Please try not to specify th here
% defaultSortOpts.th = 1e-5; % V

% wave length
defaultSortOpts.waveLength = 1.5e-3; % ms

% scale factor
defaultSortOpts.scaleFactor = 1e6; % scale wave

% cumulative variance contribution rate threshold for principal components selection
defaultSortOpts.CVCRThreshold = 0.9; % for dimensionality reduction

% k select method
defaultSortOpts.KselectionMethod = "gap";

% wave preview for spike extraction (only work with thOpt as "reselect")
defaultSortOpts.reselectT0 = 0; % start point, sec
defaultSortOpts.reselectWindow = 200; % preview window, sec

% KmeansOpts
defaultKmeansOpts.KArray = 1:10; % for elbow method and gap statistics
defaultKmeansOpts.maxIteration = 100;
defaultKmeansOpts.maxRepeat = 3;
defaultKmeansOpts.plotIterationNum = 0; % only work with mKmeans (default: kmeans)
defaultKmeansOpts.p_noise = 0.05; % for noise determination in a normalized chi distribution

defaultSortOpts.KmeansOpts = defaultKmeansOpts;