clear; clc; close all;

data_folder = "bin";
files = dir(fullfile(data_folder, "*.txt"));

% Output folder
out_folder = "outputs";
if ~exist(out_folder, "dir")
  mkdir(out_folder);
endif

for k = 1:length(files)

  filename = fullfile(data_folder, files(k).name);

  % Read TSV data
  % Column 1 = Time
  % Column 3 = Probe 1
  data = dlmread(filename, "\t");

  t = data(:,1);
  probe1 = data(:,3);

  % Keep only first 10 seconds
  t0 = t(1);
  idx = t <= (t0 + 10);

  t10 = t(idx);

  % Mean-center signal to zero axis
  p10 = probe1(idx);
  p10 = p10 - mean(p10);

  % Find local maxima
  maxima_idx = find( ...
      p10(2:end-1) > p10(1:end-2) & ...
      p10(2:end-1) > p10(3:end) ) + 1;

  % Find local minima
  minima_idx = find( ...
      p10(2:end-1) < p10(1:end-2) & ...
      p10(2:end-1) < p10(3:end) ) + 1;

  % Symmetric y-limits about zero
  ymax = max(abs(p10));
  ylim_val = 1.1 * ymax;   % 10% padding

  % Create plot
  figure("visible", "off");
  set(gcf, "position", [100 100 900 500]);

  plot(t10, p10, "b-", "linewidth", 1);
  hold on;

  % Maxima = GREEN circles
  plot(t10(maxima_idx), ...
       p10(maxima_idx), ...
       "go", ...
       "markersize", 10, ...
       "linewidth", 1);

  % Minima = RED circles
  plot(t10(minima_idx), ...
       p10(minima_idx), ...
       "ro", ...
       "markersize", 10, ...
       "linewidth", 1);

  % Apply symmetric y-axis limits
  ylim([-ylim_val ylim_val]);

  grid on;

  xlabel("Time (s)");
ylabel('Surface displacement, \eta (mm)');

  legend("Probe 2 (2.5m)", "Maxima", "Minima", ...
         "location", "eastoutside");

  % Save output image
  [~, name, ~] = fileparts(files(k).name);

  output_name = fullfile(out_folder, ...
                        [name "_probe1_peaks.png"]);

  print(output_name, "-dpng", "-r300");

  close;
endfor

disp("Done. All plots saved to the 'outputs' folder.");
