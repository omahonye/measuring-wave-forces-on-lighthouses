# Analysis

This directory contains the GNU Octave analysis scripts used to process experimental wave, acceleration, and force data for the thesis:

> Measuring Wave Forces on Lighthouses: A Scale Model Investigation

The analysis scripts are organised into three subdirectories:

```text
analysis/
├── waves/
│   Wave probe processing, FFT analysis, and wave-height calibration
├── acceleration/
│   Accelerometer response analysis
└── force/
    Load cell force processing and plotting
```

---

## Directory Contents

### `waves/`

Wave analysis scripts for processing wave probe data.

| Script | Description |
|---|---|
| `05_WavePlotter.m` | Plots wave probe time histories, mean-centres the signal, identifies local maxima and minima, and saves peak-marked figures. |
| `06_WaveFFT.m` | Performs FFT analysis on wave probe data, identifies dominant frequencies, and generates frequency plots. |
| `07_WaveHPoly.m` | Calculates wave height, estimates probe behaviour, fits polynomial relationships, and exports summary CSV files. |

### `acceleration/`

Accelerometer response analysis.

| Script | Description |
|---|---|
| `08_AccelerationComparison` | Processes accelerometer files, calculates RMS acceleration, peak acceleration, and dominant FFT frequency against significant wave height. |

### `force/`

Load cell force analysis scripts.

| Script | Description |
|---|---|
| `09_ForceComparison.m` | Processes force CSV files, calculates RMS, peak, and mean force, groups results by test condition, and plots force response against speed and wave height. |
| `10_ForcePlot.m` | Creates 2×2 subplot figures showing the four repeated force time histories for each experimental case, allowing direct visual comparison of test repeatability. |

---

## Input Data

The scripts expect input files to be placed in local working folders such as:

```text
Bin/
BIN/
Bin-Force/
SCO/
IRL/
ENG/
FR/
```

These folders are used as temporary working directories for raw or processed experimental data.

---

## Outputs

Depending on the script, outputs may include:

- PNG figures
- FFT plots
- Peak-frequency plots
- Force time-history subplots
- Processed CSV summary tables
- Polynomial coefficient files


## Requirements

The scripts were written for GNU Octave.

Some scripts require the Octave signal package:

```octave
pkg load signal
```

---

## Notes

File paths are currently defined inside each script. Before running an analysis, ensure that the expected input folder exists and contains files using the required naming convention.

The scripts are intended to reproduce the data processing workflow used in the thesis and may require adjustment when applied to new datasets.
