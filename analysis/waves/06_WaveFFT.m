pkg load signal

clear; clc; close all;

input_folder  = "Bin";
output_folder = "Output";

if ~exist(output_folder, "dir")
    mkdir(output_folder);
end

files = dir(fullfile(input_folder, "*.txt"));

speeds = [];
peak_freqs = [];

all_f  = {};
all_A1 = {};
all_A2 = {};

all_peak_speeds = [];
all_peak_freqs  = [];
all_peak_amps   = [];

f_min = 0.0;
f_max = 6.0;

for k = 1:length(files)

    filename = fullfile(input_folder, files(k).name);
    data = dlmread(filename, '\t');

    t      = data(:,1);   % time (s)
    probe2 = data(:,2);   % probe 2
    probe1 = data(:,3);   % probe 1

    dt = mean(diff(t));
    Fs = 1 / dt;
    N  = length(t);

    % mean centre
    probe1 = probe1 - mean(probe1);
    probe2 = probe2 - mean(probe2);

    % FFT
    Y1 = fft(probe1);
    Y2 = fft(probe2);

    f = (0:N-1) * (Fs / N);

    % positive frequencies only
    half = 1:floor(N/2);
    f  = f(half);
    A1 = abs(Y1(half));
    A2 = abs(Y2(half));

    % frequency cap for wave band
    valid = (f >= f_min) & (f <= f_max);
    f_cut  = f(valid);
    A1_cut = A1(valid);
    A2_cut = A2(valid);

    % store for overlay plot
    all_f{end+1}  = f_cut;
    all_A1{end+1} = A1_cut;
    all_A2{end+1} = A2_cut;

    % extract speed from filename like "10speed.txt" or "10.5speed.txt"
    token = regexp(files(k).name, '([\d\.]+)\s*speed', 'tokens', 'once');
    if isempty(token)
        token = regexp(files(k).name, '([\d\.]+)', 'tokens', 'once');
    end
    speed = str2double(token{1});

    % find all FFT peaks in probe 1
    [pks, locs] = findpeaks(A1_cut);

    if ~isempty(pks)
        threshold = 0.025 * max(A1_cut);   % keep peaks above 25% of max
        keep = pks > threshold;

        pks_kept  = pks(keep);
        locs_kept = locs(keep);

        peak_freqs_local = f_cut(locs_kept);

        all_peak_freqs  = [all_peak_freqs; peak_freqs_local(:)];
        all_peak_speeds = [all_peak_speeds; repmat(speed, length(peak_freqs_local), 1)];
        all_peak_amps   = [all_peak_amps; pks_kept(:)];
    end

    % dominant peak from probe 1
    [~, idx] = max(A1_cut);
    peak_f = f_cut(idx);

    speeds(end+1) = speed;
    peak_freqs(end+1) = peak_f;

    % per-file FFT plot
    fig = figure('visible', 'off');
    plot(f_cut, A1_cut, 'b', 'linewidth', 1.5); hold on;
    plot(f_cut, A2_cut, 'r', 'linewidth', 1.5);
    xlabel('Frequency (Hz)');
    ylabel('Amplitude');
    title(sprintf('FFT - %.3g speed', speed));
    legend('Probe 1', 'Probe 2', 'location', 'northeast');
    grid on;
    xlim([f_min f_max]);
    print(fig, fullfile(output_folder, [files(k).name(1:end-4) '_fft.png']), '-dpng', '-r300');
##    CLOSE(FIG);

end

% sort by speed
[speeds, sort_idx] = sort(speeds);
peak_freqs = peak_freqs(sort_idx);


% dominant peak frequency vs speed line plot
fig_peaks = figure;
plot(speeds, peak_freqs, '-ok', 'linewidth', 1.8, 'markersize', 6, 'markerfacecolor', 'k');
xlabel('Speed');
ylabel('Dominant Frequency from Probe 1 (Hz)');
title('Dominant FFT Peak Across All Speeds');
grid on;
print(fig_peaks, fullfile(output_folder, 'Peak_frequency_vs_speed.png'), '-dpng', '-r300');

% scatter plot of all FFT peaks at each speed
fig_scatter = figure;
scatter(all_peak_speeds, all_peak_freqs, 25, 'filled');
xlabel('Speed');
ylabel('All Detected Peak Frequencies (Hz)');
title('Scatter of FFT Peaks Across Speeds');
grid on;
ylim([f_min f_max]);
print(fig_scatter, fullfile(output_folder, 'FFT_peak_scatter.png'), '-dpng', '-r300');


% ---------------------------
% SCATTER OF ALL PERIODS (T = 1/f)
% ---------------------------

all_peak_periods = 1 ./ all_peak_freqs;

fig_period_scatter = figure;
scatter(all_peak_speeds, all_peak_periods, 25, 'filled');

xlabel('Speed');
ylabel('Wave Period T (s)');
title('Scatter of Wave Periods (T = 1/f) Across Speeds');
grid on;

print(fig_period_scatter, fullfile(output_folder, 'FFT_period_scatter.png'), '-dpng', '-r300');

% console output
disp('Speed    Dominant_Peak_Frequency_Hz');
disp([speeds(:), peak_freqs(:)]);
