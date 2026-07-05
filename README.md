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
    Python data acquisition software

analysis_octave/
    Signal processing and analysis scripts

data/
    Example datasets

figures/
    Generated figures

docs/
    Additional documentation

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

This repository is released under the MIT Licence.
