% ============================================================
% Force_Comparisons.m
%
% This script reads force CSV files from the folder:
%   Bin-Force
%
% Expected filename format:
%   1SCO20.csv
%
% Meaning:
%   1   = run number
%   SCO = tower/location
%   20  = wavemaker speed
%
% Assumptions:
%   - CSV files have a header row
%   - Force in Newtons is stored in the 4th column
%   - Force sign should be flipped on import
%
% Outputs:
%   - processed_results_by_run.csv
%   - processed_results_grouped.csv
%   - mean RMS, peak, and mean force plots vs speed
%   - mean RMS, peak, and mean force plots vs mean wave height
%   - per-tower RMS, peak, and mean force plots for all runs vs speed
%   - per-tower RMS, peak, and mean force plots for all runs vs mean wave height
%
% All outputs are saved into:
%   output/
% ============================================================

clear;
clc;
close all;

% ------------------------------------------------------------
% User settings
% ------------------------------------------------------------
data_folder = 'Bin-Force';
output_folder = 'output';

% Tower-specific quadratic polynomials converting speed to mean wave height
% mean_wave_height = a*speed^2 + b*speed + c
p_ENG = [-0.060527, 5.518241, -35.271721];
p_IRL = [-0.032023, 4.365385, -24.512359];
p_SCO = [-0.046303, 5.094531, -32.675481];

% Create output folder if it does not already exist
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

fprintf('Reading CSV files from folder: %s\n', data_folder);

% ------------------------------------------------------------
% Find all CSV files in the input folder
% ------------------------------------------------------------
files = dir(fullfile(data_folder, '*.csv'));

% Arrays/cells to store processed results from each file
runs = [];
speeds = [];
mean_wave_heights = [];
locations = {};
rms_vals = [];
peak_vals = [];
mean_vals = [];

% ------------------------------------------------------------
% Loop through each CSV file
% ------------------------------------------------------------
for k = 1:length(files)

    fname = files(k).name;
    fpath = fullfile(data_folder, fname);

    % Parse filename using regex
    tok = regexp(fname, '^(\d+)([A-Za-z]+)(\d+)\.csv$', 'tokens');

    if isempty(tok)
        fprintf('Skipping unexpected filename: %s\n', fname);
        continue;
    end

    tok = tok{1};
    run_num = str2double(tok{1});
    loc = upper(tok{2});
    spd = str2double(tok{3});

    % --------------------------------------------------------
    % Select correct mean wave height polynomial
    % based on location
    % --------------------------------------------------------
    if strcmp(loc, 'ENG')
        p = p_ENG;
    elseif strcmp(loc, 'IRL')
        p = p_IRL;
    elseif strcmp(loc, 'SCO')
        p = p_SCO;
    else
        fprintf('Skipping %s: no mean wave height polynomial defined for location %s\n', fname, loc);
        continue;
    end

    % Convert speed to mean wave height using location-specific polynomial
    mean_wave_height = polyval(p, spd);

    % Read numeric data from CSV
    try
        data = dlmread(fpath, ',', 1, 0);
    catch
        fprintf('Skipping %s: could not read file\n', fname);
        continue;
    end

    % Check that at least 4 columns exist
    if size(data, 2) < 4
        fprintf('Skipping %s: fewer than 4 columns\n', fname);
        continue;
    end

    % Read force from 4th column and flip sign
    force = -data(:, 4);
    force = force(!isnan(force));

    if isempty(force)
        fprintf('Skipping %s: no valid numeric data in column 4\n', fname);
        continue;
    end

    % Compute response metrics
    rms_force = sqrt(mean(force.^2));
    peak_force = max(abs(force));
    mean_force = mean(force);

    % Store results
    runs(end+1,1) = run_num;
    speeds(end+1,1) = spd;
    mean_wave_heights(end+1,1) = mean_wave_height;
    locations{end+1,1} = loc;
    rms_vals(end+1,1) = rms_force;
    peak_vals(end+1,1) = peak_force;
    mean_vals(end+1,1) = mean_force;
end

% ------------------------------------------------------------
% Stop if no valid files were found
% ------------------------------------------------------------
if isempty(runs)
    error('No valid CSV files found in Bin-Force.');
end

fprintf('Number of valid files read: %d\n', length(runs));

% ------------------------------------------------------------
% Save processed results by run
% ------------------------------------------------------------
fid = fopen(fullfile(output_folder, 'processed_results_by_run.csv'), 'w');
fprintf(fid, 'run,location,speed,mean_wave_height,rms,peak,mean\n');

for i = 1:length(runs)
    fprintf(fid, '%d,%s,%d,%.10f,%.10f,%.10f,%.10f\n', ...
        runs(i), locations{i}, speeds(i), mean_wave_heights(i), ...
        rms_vals(i), peak_vals(i), mean_vals(i));
end

fclose(fid);

% ------------------------------------------------------------
% Group results by location and speed
% ------------------------------------------------------------
unique_locs = unique(locations);
unique_speeds = unique(speeds);

group_loc = {};
group_speed = [];
group_mean_wave_height = [];
group_rms_mean = [];
group_rms_std = [];
group_peak_mean = [];
group_peak_std = [];
group_mean_mean = [];
group_mean_std = [];

for i = 1:length(unique_locs)
    loc = unique_locs{i};

    for j = 1:length(unique_speeds)
        sp = unique_speeds(j);

        mask = strcmp(locations, loc) & (speeds == sp);

        if any(mask)
            this_rms = rms_vals(mask);
            this_peak = peak_vals(mask);
            this_mean = mean_vals(mask);
            this_mean_wave_height = mean_wave_heights(mask);

            group_loc{end+1,1} = loc;
            group_speed(end+1,1) = sp;
            group_mean_wave_height(end+1,1) = mean(this_mean_wave_height);
            group_rms_mean(end+1,1) = mean(this_rms);
            group_peak_mean(end+1,1) = mean(this_peak);
            group_mean_mean(end+1,1) = mean(this_mean);

            if length(this_rms) > 1
                group_rms_std(end+1,1) = std(this_rms);
                group_peak_std(end+1,1) = std(this_peak);
                group_mean_std(end+1,1) = std(this_mean);
            else
                group_rms_std(end+1,1) = 0;
                group_peak_std(end+1,1) = 0;
                group_mean_std(end+1,1) = 0;
            end
        end
    end
end

% ------------------------------------------------------------
% Save grouped results
% ------------------------------------------------------------
fid = fopen(fullfile(output_folder, 'processed_results_grouped.csv'), 'w');
fprintf(fid, 'location,speed,mean_wave_height,rms_mean,rms_std,peak_mean,peak_std,mean_mean,mean_std\n');

for i = 1:length(group_speed)
    fprintf(fid, '%s,%d,%.10f,%.10f,%.10f,%.10f,%.10f,%.10f,%.10f\n', ...
        group_loc{i}, group_speed(i), group_mean_wave_height(i), ...
        group_rms_mean(i), group_rms_std(i), ...
        group_peak_mean(i), group_peak_std(i), ...
        group_mean_mean(i), group_mean_std(i));
end

fclose(fid);

% ------------------------------------------------------------
% Plot 1: Mean RMS Force by Tower vs Speed
% ------------------------------------------------------------
figure;
hold on;
leg = {};

for i = 1:length(unique_locs)
    loc = unique_locs{i};

    mask = strcmp(group_loc, loc);
    x = group_speed(mask);
    y = group_rms_mean(mask);

    [x_sorted, idx] = sort(x);
    y_sorted = y(idx);

    plot(x_sorted, y_sorted, '-o', 'linewidth', 1.5);
    leg{end+1} = loc;
end

xlabel('Wavemaker Speed', 'fontsize', 12);
ylabel('Mean RMS Force (N)', 'fontsize', 12);
title('Mean RMS Force by Tower vs Wavemaker Speed', 'fontsize', 13);
legend(leg, 'location', 'eastoutside');
grid on;
box on;
set(gca, 'fontsize', 11);
saveas(gcf, fullfile(output_folder, 'mean_rms_by_tower_speed.png'));

% ------------------------------------------------------------
% Plot 2: Mean Peak Force by Tower vs Speed
% ------------------------------------------------------------
figure;
hold on;
leg = {};

for i = 1:length(unique_locs)
    loc = unique_locs{i};

    mask = strcmp(group_loc, loc);
    x = group_speed(mask);
    y = group_peak_mean(mask);

    [x_sorted, idx] = sort(x);
    y_sorted = y(idx);

    plot(x_sorted, y_sorted, '-o', 'linewidth', 1.5);
    leg{end+1} = loc;
end

xlabel('Wavemaker Speed', 'fontsize', 12);
ylabel('Mean Peak Force (N)', 'fontsize', 12);
title('Mean Peak Force by Tower vs Wavemaker Speed', 'fontsize', 13);
legend(leg, 'location', 'eastoutside');
grid on;
box on;
set(gca, 'fontsize', 11);
saveas(gcf, fullfile(output_folder, 'mean_peak_by_tower_speed.png'));

% ------------------------------------------------------------
% Plot 3: Mean Force by Tower vs Speed
% ------------------------------------------------------------
figure;
hold on;
leg = {};

for i = 1:length(unique_locs)
    loc = unique_locs{i};

    mask = strcmp(group_loc, loc);
    x = group_speed(mask);
    y = group_mean_mean(mask);

    [x_sorted, idx] = sort(x);
    y_sorted = y(idx);

    plot(x_sorted, y_sorted, '-o', 'linewidth', 1.5);
    leg{end+1} = loc;
end

xlabel('Wavemaker Speed', 'fontsize', 12);
ylabel('Mean Force (N)', 'fontsize', 12);
title('Mean Force by Tower vs Wavemaker Speed', 'fontsize', 13);
legend(leg, 'location', 'eastoutside');
grid on;
box on;
set(gca, 'fontsize', 11);
saveas(gcf, fullfile(output_folder, 'mean_force_by_tower_speed.png'));

% ------------------------------------------------------------
% Plot 4: Mean RMS Force by Tower vs Mean Wave Height
% ------------------------------------------------------------
figure;
hold on;
leg = {};

for i = 1:length(unique_locs)
    loc = unique_locs{i};

    mask = strcmp(group_loc, loc);
    x = group_mean_wave_height(mask);
    y = group_rms_mean(mask);

    [x_sorted, idx] = sort(x);
    y_sorted = y(idx);

    plot(x_sorted, y_sorted, '-o', 'linewidth', 1.5);
    leg{end+1} = loc;
end

xlabel('Mean Wave Height (mm)', 'fontsize', 12);
ylabel('Mean RMS Force (N)', 'fontsize', 12);
title('Mean RMS Force by Tower vs Mean Wave Height', 'fontsize', 13);
legend(leg, 'location', 'eastoutside');
grid on;
box on;
set(gca, 'fontsize', 11);
saveas(gcf, fullfile(output_folder, 'mean_rms_by_tower_mean_wave_height.png'));

% ------------------------------------------------------------
% Plot 5: Mean Peak Force by Tower vs Mean Wave Height
% ------------------------------------------------------------
figure;
hold on;
leg = {};

for i = 1:length(unique_locs)
    loc = unique_locs{i};

    mask = strcmp(group_loc, loc);
    x = group_mean_wave_height(mask);
    y = group_peak_mean(mask);

    [x_sorted, idx] = sort(x);
    y_sorted = y(idx);

    plot(x_sorted, y_sorted, '-o', 'linewidth', 1.5);
    leg{end+1} = loc;
end

xlabel('Mean Wave Height (mm)', 'fontsize', 12);
ylabel('Mean Peak Force (N)', 'fontsize', 12);
title('Mean Peak Force by Tower vs Mean Wave Height', 'fontsize', 13);
legend(leg, 'location', 'eastoutside');
grid on;
box on;
set(gca, 'fontsize', 11);
saveas(gcf, fullfile(output_folder, 'mean_peak_by_tower_mean_wave_height.png'));

% ------------------------------------------------------------
% Plot 6: Mean Force by Tower vs Mean Wave Height
% ------------------------------------------------------------
figure;
hold on;
leg = {};

for i = 1:length(unique_locs)
    loc = unique_locs{i};

    mask = strcmp(group_loc, loc);
    x = group_mean_wave_height(mask);
    y = group_mean_mean(mask);

    [x_sorted, idx] = sort(x);
    y_sorted = y(idx);

    plot(x_sorted, y_sorted, '-o', 'linewidth', 1.5);
    leg{end+1} = loc;
end

xlabel('Mean Wave Height (mm)', 'fontsize', 12);
ylabel('Mean Force (N)', 'fontsize', 12);
title('Mean Force by Tower vs Mean Wave Height', 'fontsize', 13);
legend(leg, 'location', 'eastoutside');
grid on;
box on;
set(gca, 'fontsize', 11);
saveas(gcf, fullfile(output_folder, 'mean_force_by_tower_mean_wave_height.png'));

% ------------------------------------------------------------
% Per-tower plots showing all runs vs Speed and vs Mean Wave Height
% ------------------------------------------------------------
for i = 1:length(unique_locs)
    loc = unique_locs{i};

    mask_loc = strcmp(locations, loc);
    loc_runs = unique(runs(mask_loc));

    % RMS vs Speed
    figure;
    hold on;
    leg = {};

    for r = 1:length(loc_runs)
        run_num = loc_runs(r);
        mask = strcmp(locations, loc) & (runs == run_num);

        x = speeds(mask);
        y = rms_vals(mask);

        [x_sorted, idx] = sort(x);
        y_sorted = y(idx);

        plot(x_sorted, y_sorted, '-o', 'linewidth', 1.5);
        leg{end+1} = sprintf('R%d', run_num);
    end

    xlabel('Wavemaker Speed', 'fontsize', 12);
    ylabel('RMS Force (N)', 'fontsize', 12);
    title(sprintf('%s - RMS Force vs Wavemaker Speed (All Runs)', loc), 'fontsize', 13);
    legend(leg, 'location', 'eastoutside');
    grid on;
    box on;
    set(gca, 'fontsize', 11);
    saveas(gcf, fullfile(output_folder, sprintf('%s_rms_speed.png', loc)));

    % Peak vs Speed
    figure;
    hold on;
    leg = {};

    for r = 1:length(loc_runs)
        run_num = loc_runs(r);
        mask = strcmp(locations, loc) & (runs == run_num);

        x = speeds(mask);
        y = peak_vals(mask);

        [x_sorted, idx] = sort(x);
        y_sorted = y(idx);

        plot(x_sorted, y_sorted, '-o', 'linewidth', 1.5);
        leg{end+1} = sprintf('R%d', run_num);
    end

    xlabel('Wavemaker Speed', 'fontsize', 12);
    ylabel('Peak |Force| (N)', 'fontsize', 12);
    title(sprintf('%s - Peak Force vs Wavemaker Speed (All Runs)', loc), 'fontsize', 13);
    legend(leg, 'location', 'eastoutside');
    grid on;
    box on;
    set(gca, 'fontsize', 11);
    saveas(gcf, fullfile(output_folder, sprintf('%s_peak_speed.png', loc)));

    % Mean vs Speed
    figure;
    hold on;
    leg = {};

    for r = 1:length(loc_runs)
        run_num = loc_runs(r);
        mask = strcmp(locations, loc) & (runs == run_num);

        x = speeds(mask);
        y = mean_vals(mask);

        [x_sorted, idx] = sort(x);
        y_sorted = y(idx);

        plot(x_sorted, y_sorted, '-o', 'linewidth', 1.5);
        leg{end+1} = sprintf('R%d', run_num);
    end

    xlabel('Wavemaker Speed', 'fontsize', 12);
    ylabel('Mean Force (N)', 'fontsize', 12);
    title(sprintf('%s - Mean Force vs Speed (All Runs)', loc), 'fontsize', 13);
    legend(leg, 'location', 'eastoutside');
    grid on;
    box on;
    set(gca, 'fontsize', 11);
    saveas(gcf, fullfile(output_folder, sprintf('%s_mean_speed.png', loc)));

    % RMS vs Mean Wave Height
    figure;
    hold on;
    leg = {};

    for r = 1:length(loc_runs)
        run_num = loc_runs(r);
        mask = strcmp(locations, loc) & (runs == run_num);

        x = mean_wave_heights(mask);
        y = rms_vals(mask);

        [x_sorted, idx] = sort(x);
        y_sorted = y(idx);

        plot(x_sorted, y_sorted, '-o', 'linewidth', 1.5);
        leg{end+1} = sprintf('R%d', run_num);
    end

    xlabel('Mean Wave Height (mm)', 'fontsize', 12);
    ylabel('RMS Force (N)', 'fontsize', 12);
    title(sprintf('%s - RMS Force vs Mean Wave Height (All Runs)', loc), 'fontsize', 13);
    legend(leg, 'location', 'eastoutside');
    grid on;
    box on;
    set(gca, 'fontsize', 11);
    saveas(gcf, fullfile(output_folder, sprintf('%s_rms_mean_wave_height.png', loc)));

    % Peak vs Mean Wave Height
    figure;
    hold on;
    leg = {};

    for r = 1:length(loc_runs)
        run_num = loc_runs(r);
        mask = strcmp(locations, loc) & (runs == run_num);

        x = mean_wave_heights(mask);
        y = peak_vals(mask);

        [x_sorted, idx] = sort(x);
        y_sorted = y(idx);

        plot(x_sorted, y_sorted, '-o', 'linewidth', 1.5);
        leg{end+1} = sprintf('R%d', run_num);
    end

    xlabel('Mean Wave Height (mm)', 'fontsize', 12);
    ylabel('Peak |Force| (N)', 'fontsize', 12);
    title(sprintf('%s - Peak Force vs Mean Wave Height (All Runs)', loc), 'fontsize', 13);
    legend(leg, 'location', 'eastoutside');
    grid on;
    box on;
    set(gca, 'fontsize', 11);
    saveas(gcf, fullfile(output_folder, sprintf('%s_peak_mean_wave_height.png', loc)));

    % Mean vs Mean Wave Height
    figure;
    hold on;
    leg = {};

    for r = 1:length(loc_runs)
        run_num = loc_runs(r);
        mask = strcmp(locations, loc) & (runs == run_num);

        x = mean_wave_heights(mask);
        y = mean_vals(mask);

        [x_sorted, idx] = sort(x);
        y_sorted = y(idx);

        plot(x_sorted, y_sorted, '-o', 'linewidth', 1.5);
        leg{end+1} = sprintf('R%d', run_num);
    end

    xlabel('Mean Wave Height (mm)', 'fontsize', 12);
    ylabel('Mean Force (N)', 'fontsize', 12);
    title(sprintf('%s - Mean Force vs Mean Wave Height (All Runs)', loc), 'fontsize', 13);
    legend(leg, 'location', 'eastoutside');
    grid on;
    box on;
    set(gca, 'fontsize', 11);
    saveas(gcf, fullfile(output_folder, sprintf('%s_mean_mean_wave_height.png', loc)));
end

fprintf('\nDone.\n');
fprintf('Saved into folder: %s\n', output_folder);
fprintf('Files created include:\n');
fprintf(' - processed_results_by_run.csv\n');
fprintf(' - processed_results_grouped.csv\n');
fprintf(' - mean_rms_by_tower_speed.png\n');
fprintf(' - mean_peak_by_tower_speed.png\n');
fprintf(' - mean_force_by_tower_speed.png\n');
fprintf(' - mean_rms_by_tower_mean_wave_height.png\n');
fprintf(' - mean_peak_by_tower_mean_wave_height.png\n');
fprintf(' - mean_force_by_tower_mean_wave_height.png\n');
fprintf(' - per-tower RMS, Peak, and Mean plots vs speed\n');
fprintf(' - per-tower RMS, Peak, and Mean plots vs mean wave height\n');% ============================================================
