# Measuring Wave Forces on Lighthouses: A Scale Model Investigation

> **Master of Engineering Thesis**  
> **University of Galway**  
> **Author:** Eoghan O'Mahony  
> **Submission:** May 2026

---

## Overview

This repository contains the complete software developed for the Master's thesis:

> **Measuring Wave Forces on Lighthouses: A Scale Model Investigation**

The project investigated wave-induced loading on a scaled lighthouse model through laboratory experimentation. A custom DAQ experimental system was developed using embedded microcontrollers, load cell instrumentation and accelerometers to capture structural response during wave impacts.

The repository contains the embedded firmware, data acquisition software and GNU Octave analysis scripts used to collect, process and analyse the experimental data presented in the thesis.

---
## Repository Structure


```text
embedded/
    Arduino and Raspberry Pi Pico firmware

serial_capture/
    Python scripts for serial data acquisition

analysis/
    waves/
        MATLAB scripts for wave analysis, FFT, and polynomial fitting

    acceleration/
        MATLAB scripts for acceleration comparison and analysis

    force/
        MATLAB scripts for force comparison and visualisation

data/
    Experimental datasets

docs/
    Thesis and supporting project documentation
```
---
## Experimental System

The experimental setup consisted of:

- Arduino-based load cell acquisition
- Raspberry Pi Pico accelerometer acquisition
- Python serial communication for data logging
- GNU Octave for signal processing and analysis

### Hardware

- Arduino Uno
- HX711 Load Cell Amplifier
- Load Cell
- Raspberry Pi Pico
- ADXL345 Accelerometer

### Software

- Arduino IDE
- Thonny MicroPython
- Python 3
- GNU Octave

Python packages used include:
- pyserial
- numpy
- pandas

---

## Data

The original experimental datasets are not included in this repository.

Where possible, representative sample datasets are provided to demonstrate the analysis workflow.

---

## Citation

If you use this repository in academic work, please cite the associated Master's thesis:

> O'Mahony, E. (2026). *Measuring Wave Forces on Lighthouses: A Scale Model Investigation*. M.E. Thesis. University of Galway.

A `CITATION.cff` file is also included to provide machine-readable citation metadata.

---

## Licence

Except where otherwise stated, all source code, firmware, software, scripts, and other software components contained in this repository are licensed under the MIT License. The full terms of the MIT License are available in the repository's root LICENSE file.

All documentation and non-software materials contained within the docs/ directory, including but not limited to the thesis manuscript, figures, diagrams, reports, and supporting documentation, are licensed under the Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0) License, unless explicitly stated otherwise. The applicable license terms are provided in docs/LICENSE.

For the avoidance of doubt, the MIT License does not apply to the contents of the docs/ directory, and the CC BY-NC 4.0 License does not apply to the software components of this repository.
