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
defaultSortOpts.scaleFactor = 1e6;

% cumulative variance contribution rate threshold for principal components selection
defaultSortOpts.CVCRThreshold = 0.9;

% k select method
defaultSortOpts.KselectionMethod = "gap";

% using reselect thOpt, start time of previewed wave
defaultSortOpts.reselectT0 = 0;

% KmeansOpts
defaultKmeansOpts.KArray = 1:10;
defaultKmeansOpts.maxIteration = 100;
defaultKmeansOpts.maxRepeat = 3;
defaultKmeansOpts.plotIterationNum = 0;

defaultSortOpts.KmeansOpts = defaultKmeansOpts;