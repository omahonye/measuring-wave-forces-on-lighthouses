# Data Capture Scripts

This folder contains the Python scripts used to capture experimental data from the two different measurement systems:

- **`03_CaptureArduino.py`** – Records **load measurements** from an **HX711 load cell amplifier** connected to an Arduino and saves the data as a CSV file.
- **`04_CapturePico.py`** – Records **acceleration measurements** from an **ADXL345 accelerometer** connected to a Raspberry Pi Pico, processes the data, and exports both the raw binary data and processed CSV file.

Both scripts prompt for a unique test name (e.g. `SCO22`) to organise experimental results and prevent accidental overwriting of existing data.

---

## Files

### `03_CaptureArduino.py`

Captures load cell data streamed directly from the Arduino via an **HX711 load cell amplifier**.

**Features**

- Connects to the Arduino via USB serial.
- Records load measurements.
- Prompts for a test name (e.g. `SCO22`).
- Saves the recorded data as a CSV file.
- Prevents accidental overwriting of existing files.

**Typical output**

```text
logs/
└── SCO22.csv
```

---

### `04_CapturePico.py`

Captures acceleration data from an **ADXL345 accelerometer** connected to a Raspberry Pi Pico.

Unlike the Arduino workflow, the Pico stores the acceleration data in memory before transmitting it to the computer.

**Features**

- Sends the `GO` command to the Pico to begin data acquisition.
- Receives the binary data stream.
- Saves the raw data as a `.bin` file.
- Converts raw ADXL345 counts to acceleration (m/s²).
- Removes sensor bias and the static gravity component.
- Generates plots of the processed data.
- Exports the processed data to a CSV file.
- Prevents accidental overwriting of existing `.bin` and `.csv` files.

**Typical output**

```text
logs/
├── SCO22.bin
└── SCO22.csv
```
