# Embedded Firmware

This folder contains the embedded software used to acquire experimental data from the instrumentation hardware. Two implementations are provided:

- **`01_EmbedArduino.ino`** – Arduino firmware for acquiring **load measurements** from an **HX711 load cell amplifier**.
- **`02_EmbedPico.py`** – Raspberry Pi Pico firmware for acquiring **acceleration measurements** from an **ADXL345 accelerometer**.

Each firmware is intended to be used with its corresponding Python capture script.

---

## Files

### `01_EmbedArduino.ino`

Arduino firmware for reading load measurements from an HX711 load cell amplifier.

**Features**

- Initializes the HX711 amplifier.
- Continuously reads load cell measurements.
- Outputs calibrated load values via the USB serial connection.
- Intended for use with `CaptureArduino.py`.

---

### `02_EmbedPico.ino`

Raspberry Pi Pico firmware for recording acceleration data from an ADXL345 accelerometer.

**Features**

- Communicates with the ADXL345 using the I²C interface.
- Samples acceleration at a fixed sampling frequency.
- Stores samples in memory during acquisition.
- Waits for the `GO` command from the host computer.
- Transmits the recorded data as a binary stream.
- Intended for use with `CapturePico.py`.

---

## Hardware Connections

### Arduino + HX711

| HX711 | Arduino |
|--------|----------|
| VCC | 5 V |
| GND | GND |
| DT | *Pin 4* |
| SCK | *Pin 5* |

The load cell should be connected to the HX711 according to the manufacturer's wiring.

---

### Raspberry Pi Pico + ADXL345

| ADXL345 | Raspberry Pi Pico |
|----------|-------------------|
| VIN | 3.3 V |
| GND | GND |
| SDA | *GPIO 4* |
| SCL | *GPIO 5* |

The ADXL345 communicates with the Pico via the I²C interface.

---

## Uploading the Firmware

### Arduino

1. Open `01_EmbedArduino.ino` in the Arduino IDE.
2. Select the correct Arduino board.
3. Select the correct serial port.
4. Compile and upload the sketch.

---

### Raspberry Pi Pico

1. Open `02_EmbedPico.ino` in the Thonny IDE.
2. Select the Raspberry Pi Pico board.
3. Select the correct serial port.
4. Save as *main.py* to ensure the programme autoruns on bootup
5. Compile and upload the firmware to local memory on the Pico.

---

## Operation

### Arduino

After uploading, the firmware continuously streams load measurements over the USB serial connection.

The accompanying `CaptureArduino.py` script records these measurements and saves them as a CSV file.

The IDE must not be running the serial logger at the same time as this causes a bottleneck on the capture programme.

---

### Raspberry Pi Pico

After uploading, the Pico waits for a command from the host computer.

When it receives

```text
GO
```

it:

1. Begins sampling acceleration from the ADXL345.
2. Stores the samples in memory.
3. Sends a binary data packet to the computer once acquisition is complete.

The accompanying `CapturePico.py` script receives the binary data, processes it, generates plots, and exports the processed results as a CSV file.

> **Important:** If the firmware has been uploaded or executed using **Thonny**, close Thonny before running `04_CapturePico.py`. Only one application can access the Pico's serial port at a time, so leaving Thonny open will prevent the Python capture script from communicating with the device.
---

## Notes

- Ensure the hardware pin assignments in the firmware match the physical wiring.
- The sampling frequency configured in `02_EmbedPico.ino` should match the value specified in `CapturePico.py`.
- The Arduino and Pico firmware are independent and are designed to be used with their corresponding Python capture scripts hosted on this github.
