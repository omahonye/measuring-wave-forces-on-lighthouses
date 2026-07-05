clear; clc; close all;

% Folder containing input CSV files
data_folder = "Bin-Force";

% Folder where subplot figures will be saved
output_folder = "force_subplots";

% Create output folder if it does not already exist
if !exist(output_folder, "dir")
    mkdir(output_folder);
endif

% Get list of all CSV files in the data folder
files = dir(fullfile(data_folder, "*.csv"));

% ------------------------------------------------------------
% Extract location and speed information from filenames
%
% Expected filename format:
%   <test number><location><speed>.csv
% Example:
%   1A10.csv  -> Test 1, Location A, Speed 10
% ------------------------------------------------------------
all_locations = {};
all_speeds = [];

for k = 1:length(files)

    fname = files(k).name;

    % Extract test number, location and speed using regular expression
    tok = regexp(fname, '^(\d+)([A-Za-z]+)(\d+)\.csv$', 'tokens');

    % Skip files that do not match the expected naming convention
    if isempty(tok)
        continue;
    endif

    tok = tok{1};

    loc = upper(tok{2});
    spd = str2double(tok{3});

    % Store metadata for grouping later
    all_locations{end+1} = loc;
    all_speeds(end+1) = spd;

endfor

% Get unique locations and speeds present in the dataset
unique_locations = unique(all_locations);
unique_speeds = unique(all_speeds);

% ------------------------------------------------------------
% Generate one figure for every location-speed combination
% ------------------------------------------------------------
for i = 1:length(unique_locations)

    loc = unique_locations{i};

    for j = 1:length(unique_speeds)

        spd = unique_speeds(j);

        matching = {};

        % ----------------------------------------------------
        % Find all files matching the current location and speed
        % ----------------------------------------------------
        for k = 1:length(files)

            fname = files(k).name;

            tok = regexp(fname, ...
                '^(\d+)([A-Za-z]+)(\d+)\.csv$', ...
                'tokens');

            if isempty(tok)
                continue;
            endif

            tok = tok{1};

            this_loc = upper(tok{2});
            this_spd = str2double(tok{3});

            % Keep files with matching location and speed
            if strcmp(this_loc, loc) && this_spd == spd
                matching{end+1} = fname;
            endif

        endfor

        % Skip if no files exist for this combination
        if isempty(matching)
            continue;
        endif

        % ----------------------------------------------------
        % Create an invisible figure for batch processing
        % ----------------------------------------------------
        figure("visible", "off");
        set(gcf, "position", [100 100 1000 700]);

        % Used to determine common y-axis limits
        ymax_global = 0;

        % ----------------------------------------------------
        % First pass:
        % Read every file and determine the maximum absolute
        % force value after mean centering so all subplots use
        % identical y-axis limits.
        % ----------------------------------------------------
        for m = 1:length(matching)

            data = dlmread( ...
                fullfile(data_folder, matching{m}), ...
                ",", 1, 0);

            % Ignore empty or malformed files
            if isempty(data) || size(data,2) < 4
                continue;
            endif

            % Force is stored in column 4 (sign inverted)
            force = -data(:,4);

            % Remove missing values
            force = force(!isnan(force));

            if isempty(force)
                continue;
            endif

            % Remove DC offset from the signal
            force = force - mean(force);

            % Update global maximum force magnitude
            ymax_global = max( ...
                ymax_global, ...
                max(abs(force)));

        endfor

        % Prevent invalid y-axis limits
        if ymax_global == 0
            ymax_global = 1;
        endif

        % ----------------------------------------------------
        % Second pass:
        % Plot each matching file in a 2×2 subplot layout.
        % ----------------------------------------------------
        for m = 1:4

            subplot(2,2,m);

            % If fewer than four tests exist, leave subplot blank
            if m > length(matching)

                axis off;
                title(sprintf("Test %d", m));

                continue;
            endif

            data = dlmread( ...
                fullfile(data_folder, matching{m}), ...
                ",", 1, 0);

            % Skip invalid files
            if isempty(data) || size(data,2) < 4

                axis off;
                title(sprintf("Test %d", m));

                continue;
            endif

            % Extract time and force data
            time = data(:,1);
            force = -data(:,4);

            % Remove samples containing NaN values
            valid = !isnan(time) & !isnan(force);

            time = time(valid);
            force = force(valid);

            if isempty(force)

                axis off;
                title(sprintf("Test %d", m));

                continue;
            endif

            % Remove mean force to centre the signal about zero
            force = force - mean(force);

            % --------------------------------------------
            % Plot force against time
            % --------------------------------------------
            plot(time, force, ...
                "b-", ...
                "linewidth", 1.2);

            % Apply identical y-axis limits to every subplot
            ylim([-1.1*ymax_global 1.1*ymax_global]);

            grid on;
            box on;

            xlabel("Time (s)");
            ylabel("Force (N)");

            title(sprintf("Test %d", m));

        endfor

        % ----------------------------------------------------
        % Save figure and close it before processing the next
        % location-speed combination.
        % ----------------------------------------------------
        saveas(gcf, ...
            fullfile(output_folder, ...
            sprintf("%s_%d_subplot.png", ...
            loc, spd)));

        close;

    endfor
endfor

disp("Done.");
