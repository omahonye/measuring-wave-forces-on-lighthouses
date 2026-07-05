clear;
clc;
close all;

top_folder = 'BIN';
output_folder = 'output_Hs_and_transfer';
poly_order_speed = 2;
poly_order_transfer = 2;

if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

folder_info = dir(top_folder);
is_subfolder = [folder_info.isdir];
folder_names = {folder_info(is_subfolder).name};
folder_names = folder_names(~ismember(folder_names, {'.', '..'}));

fprintf('Found %d run-set folders.\n', numel(folder_names));

for f = 1:numel(folder_names)

    set_name = folder_names{f};
    set_path = fullfile(top_folder, set_name);
    set_output = fullfile(output_folder, set_name);

    if ~exist(set_output, 'dir')
        mkdir(set_output);
    end

    fprintf('\nProcessing set: %s\n', set_name);

    txt_files = dir(fullfile(set_path, '*.txt'));

    if isempty(txt_files)
        fprintf('  No TXT files found in %s\n', set_path);
        continue;
    end

    results = {};
    row = 1;

    for k = 1:numel(txt_files)

        filename = txt_files(k).name;
        filepath = fullfile(set_path, filename);

        data = dlmread(filepath, '\t', 1, 0);

        if size(data, 2) < 3
            fprintf('    Skipping %s (not enough columns)\n', filename);
            continue;
        end

        rear_probe  = data(:,2);
        front_probe = data(:,3);

        [~, name_only, ~] = fileparts(filename);
        tokens = regexp(lower(name_only), '(\d+)\s*speed', 'tokens');

        if isempty(tokens)
            fprintf('    Could not extract speed from %s\n', filename);
            continue;
        end

        speed = str2double(tokens{1}{1});

        % Demean front probe for zero up-crossing analysis
        front_mean = mean(front_probe);
        eta_front = front_probe - front_mean;

        % Zero up-crossing indices
        up_idx = find(eta_front(1:end-1) < 0 & eta_front(2:end) >= 0);

        wave_heights = [];

        if numel(up_idx) >= 2
            for i = 1:numel(up_idx)-1
                seg_start = up_idx(i) + 1;
                seg_end   = up_idx(i+1);

                if seg_end <= seg_start
                    continue;
                end

                segment_eta = eta_front(seg_start:seg_end);

                H_i = max(segment_eta) - min(segment_eta);

                if isfinite(H_i) && H_i > 0
                    wave_heights(end+1,1) = H_i;
                end
            end
        end

        if isempty(wave_heights)
            fprintf('    No valid waves found in %s\n', filename);
            continue;
        end

        % Significant wave height from highest one-third
        sorted_heights = sort(wave_heights, 'descend');
        n_top = max(1, ceil(numel(sorted_heights)/3));
        Hs_front = mean(sorted_heights(1:n_top));

        % Probe amplitudes for transfer comparison
        front_amp = (max(front_probe) - min(front_probe)) / 2;
        rear_amp  = (max(rear_probe)  - min(rear_probe))  / 2;

        if front_amp ~= 0
            transfer_ratio = rear_amp / front_amp;
        else
            transfer_ratio = NaN;
        end

        results(row,:) = {filename, speed, Hs_front, front_amp, rear_amp, transfer_ratio};
        row = row + 1;
    end

    if isempty(results)
        fprintf('  No valid results for %s\n', set_name);
        continue;
    end

    speed = cell2mat(results(:,2));
    Hs_front = cell2mat(results(:,3));
    front_amp = cell2mat(results(:,4));
    rear_amp = cell2mat(results(:,5));
    transfer_ratio = cell2mat(results(:,6));

    [speed_sorted, idx] = sort(speed);
    Hs_front = Hs_front(idx);
    front_amp = front_amp(idx);
    rear_amp = rear_amp(idx);
    transfer_ratio = transfer_ratio(idx);

    % Polynomial fits
    p_hs = polyfit(speed_sorted, Hs_front, poly_order_speed);
    p_transfer = polyfit(front_amp, rear_amp, poly_order_transfer);

    speed_fit = linspace(min(speed_sorted), max(speed_sorted), 200);
    hs_fit = polyval(p_hs, speed_fit);

    front_fit = linspace(min(front_amp), max(front_amp), 200);
    rear_fit = polyval(p_transfer, front_fit);

    % ------------------------------------------------------------
    % Plot 1: Hs vs speed
    % ------------------------------------------------------------
    fig1 = figure('visible', 'off');
    plot(speed_sorted, Hs_front, 'o', 'markersize', 7); hold on;
    plot(speed_fit, hs_fit, '-', 'linewidth', 1.5);
    grid on;
    xlabel('Wavemaker speed');
    ylabel('Mean Wave Height, H (mm)');
    title([set_name ' - Hs vs Wavemaker Speed']);
    legend('Measured data', 'Polynomial fit', 'location', 'northwest');
    saveas(fig1, fullfile(set_output, 'Hs_vs_speed.png'));
    close(fig1);

    % ------------------------------------------------------------
    % Plot 2: Rear probe vs front probe
    % ------------------------------------------------------------
    fig2 = figure('visible', 'off');
    plot(front_amp, rear_amp, 'o', 'markersize', 7); hold on;
    plot(front_fit, rear_fit, '-', 'linewidth', 1.5);
    grid on;
    xlabel('Front probe amplitude');
    ylabel('Rear probe amplitude');
    title([set_name ' - Rear Probe vs Front Probe']);
    legend('Measured data', 'Polynomial fit', 'location', 'northwest');
    saveas(fig2, fullfile(set_output, 'rear_vs_front_probe.png'));
    close(fig2);

    % ------------------------------------------------------------
    % Save summary CSV
    % ------------------------------------------------------------
    out_csv = fullfile(set_output, 'Hs_and_transfer_summary.csv');
    fid = fopen(out_csv, 'w');
    fprintf(fid, 'file,speed,Hs_front,front_amp,rear_amp,transfer_ratio\n');

    for r = 1:size(results,1)
        fprintf(fid, '%s,%.6f,%.6f,%.6f,%.6f,%.6f\n', ...
            results{r,1}, results{r,2}, results{r,3}, ...
            results{r,4}, results{r,5}, results{r,6});
    end
    fclose(fid);

    % ------------------------------------------------------------
    % Save polynomial coefficients
    % ------------------------------------------------------------
    coeff_csv = fullfile(set_output, 'polynomial_coefficients.csv');
    fid = fopen(coeff_csv, 'w');
    fprintf(fid, 'model,a2,a1,a0\n');
    fprintf(fid, 'Hs_vs_speed,%.12f,%.12f,%.12f\n', p_hs(1), p_hs(2), p_hs(3));
    fprintf(fid, 'rear_vs_front_probe,%.12f,%.12f,%.12f\n', p_transfer(1), p_transfer(2), p_transfer(3));
    fclose(fid);

    fprintf('  %s Hs polynomial:\n', set_name);
    fprintf('    Hs (mm) = %.6f*speed^2 + %.6f*speed + %.6f\n', ...
        p_hs(1), p_hs(2), p_hs(3));

    fprintf('  %s transfer polynomial:\n', set_name);
    fprintf('    rear = %.6f*(front)^2 + %.6f*(front) + %.6f\n', ...
        p_transfer(1), p_transfer(2), p_transfer(3));

    fprintf('  Saved outputs to %s\n', set_output);
end

fprintf('\nDone.\n');
