function sortResult = initSortResult(N)
narginchk(0, 1);

if nargin < 1
    N = 1;
end

run(fullfile(getRootDirPath(fileparts(mfilename("fullpath")), 1), "config\defaultConfig.m"));

fields = {'chanIdx', 'wave', 'spikeAmp', 'sortOpts', 'th', 'spikeTimeAll', ...
          'clusterIdx', 'noiseClusterIdx', 'K', 'KArray', 'SSEs', 'gaps', ...
          'pcaData', 'clusterCenter'};
temp = cellfun(@(x) {x, cell(N, 1)}, fields, "UniformOutput", false);
temp = cat(2, temp{:});
sortResult = struct(temp{:});
sortResult = addfield(sortResult, "sortOpts", repmat({defaultSortOpts}, N, 1));
return;
end