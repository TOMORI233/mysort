function data = TDTDataConvertor(rawWave, fs, waveChan, spikeTime, spikeWaveform, spikeChan)
narginchk(2, 6);

if nargin < 3 || isempty(waveChan)
    waveChan = (1:size(rawWave, 1))';
end

if nargin < 4
    spikeTime = [];
end

if nargin < 5
    spikeWaveform = [];
end

if nargin < 6
    spikeChan = [];
end

data.streams.Wave.data = rawWave; % volt
data.streams.Wave.fs = fs; % Hz
data.streams.Wave.channel = waveChan;

data.snips.eNeu.data = spikeWaveform; % volt
data.snips.eNeu.ts = spikeTime; % sec
data.snips.eNeu.fs = fs; % Hz
data.snips.eNeu.chan = spikeChan;
end