import serial
import struct
import time
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

# ================= USER SETTINGS =================
PORT = "/dev/cu.usbmodem101"
BAUD = 115200
FS = 400              # Hz
CAPTURE_SECONDS = 30
WAIT_MARGIN = 10
SCALE_G = 0.0039      # g per LSB (ADXL345 full-res)
G = 9.80665
MAGIC = b"ADXL"
# =================================================

def read_exact(ser, n):
    data = bytearray()
    while len(data) < n:
        chunk = ser.read(n - len(data))
        if not chunk:
            continue
        data.extend(chunk)
    return bytes(data)

def capture_from_pico(outfile: Path):
    with serial.Serial(PORT, BAUD, timeout=0.2) as ser:
        time.sleep(1.0)
        ser.reset_input_buffer()

        print("Triggering Pico capture…")
        ser.write(b"GO\n")
        ser.flush()

        deadline = time.time() + CAPTURE_SECONDS + WAIT_MARGIN
        buf = bytearray()

        # Wait for header
        while True:
            if time.time() > deadline:
                raise RuntimeError("Timed out waiting for ADXL header")

            b = ser.read(1)
            if not b:
                continue

            buf += b

            if buf.endswith(MAGIC):
                break

            if len(buf) > 64:
                buf = buf[-64:]

        nsamp = struct.unpack("<I", read_exact(ser, 4))[0]
        payload = read_exact(ser, nsamp * 6)

    with open(outfile, "wb") as f:
        f.write(MAGIC)
        f.write(struct.pack("<I", nsamp))
        f.write(payload)

    print(f"Saved raw data: {outfile}")
    return nsamp

def read_bin_and_plot(binfile: Path):
    with open(binfile, "rb") as f:
        if f.read(4) != MAGIC:
            raise RuntimeError("Invalid file header")

        nsamp = struct.unpack("<I", f.read(4))[0]
        raw = f.read(nsamp * 6)

    data = np.frombuffer(raw, dtype="<i2").reshape((nsamp, 3))
    t = np.arange(nsamp) / FS

    ax = data[:, 0] * SCALE_G * G
    ay = data[:, 1] * SCALE_G * G
    az = data[:, 2] * SCALE_G * G

    # ============================================================
    # Mean-centre acceleration to remove bias and gravity
    # ============================================================
    ax_mean = np.mean(ax)
    ay_mean = np.mean(ay)
    az_mean = np.mean(az)

    ax_clean = ax - ax_mean   # remove horizontal bias (X)
    ay_clean = ay - ay_mean   # remove horizontal bias (Y)
    az_clean = az - az_mean   # remove gravity + bias (Z)

    # ============================================================
    # Generate resultant acceleration magnitude
    # ============================================================
    ar = np.sqrt(ax_clean**2 + ay_clean**2 + az_clean**2)


    # ---- Plot XY ----
    plt.figure(figsize=(10, 4))
    plt.plot(t, ax_clean, label="ax")
    plt.plot(t, ay_clean, label="ay")
    plt.xlabel("Time (s)")
    plt.ylabel("Acceleration (m/s²)")
    plt.title(binfile.stem)
    plt.legend()
    plt.tight_layout()
    plt.show()

    # ---- Plot Z ----
    plt.figure(figsize=(10, 4))
    plt.plot(t, az_clean, label="az")
    plt.xlabel("Time (s)")
    plt.ylabel("Acceleration (m/s²)")
    plt.title(binfile.stem)
    plt.legend()
    plt.tight_layout()
    plt.show()

    # ---- Plot ar horizontal ----
    plt.figure(figsize=(10, 4))
    plt.plot(t, ar, label="ar")
    plt.xlabel("Time (s)")
    plt.ylabel("Resultant Acceleration (m/s²)")
    plt.title(binfile.stem)
    plt.legend()
    plt.tight_layout()
    plt.show()

    # ============================================================
    # Scatter plot of horizontal acceleration components
    # ============================================================
    plt.figure(figsize=(6, 6))
    plt.scatter(ax_clean, ay_clean, s=4, alpha=0.4)
    plt.axhline(0, color="k", linewidth=0.5)
    plt.axvline(0, color="k", linewidth=0.5)
    plt.xlabel("ax (m/s²)")
    plt.ylabel("ay (m/s²)")
    plt.title(f"{binfile.stem} – Horizontal acceleration phase plot")
    plt.axis("equal")
    plt.grid(True, linewidth=0.3)
    plt.tight_layout()
    plt.show()

    # ---- Save CSV ----
    df = pd.DataFrame({
        "time_s": t,
        "ax_ms2": ax_clean,
        "ay_ms2": ay_clean,
        "az_ms2": az_clean,
        "ah_ms2": ah,
        "theta_y_deg": theta_y_deg
    })

    csvfile = binfile.with_suffix(".csv")

    if csvfile.exists():
        raise FileExistsError(
            f"Error: '{csvfile.name}' already exists. "
            "CSV export stopped to avoid overwriting data."
        )

    df.to_csv(csvfile, index=False)
    print(f"Saved CSV: {csvfile}")

def main():
    # ================= FILE NAME INPUT =================
    name = input("Enter test name (e.g. SCO22): ").strip()

    outdir = Path("logs")
    outdir.mkdir(exist_ok=True)

    outfile = outdir / f"{name}.bin"

    # Prevent accidental overwrite
    if outfile.exists():
        raise FileExistsError(
            f"Error: '{outfile.name}' already exists. "
            "Please choose a different test name."
        )

    nsamp = capture_from_pico(outfile)
    print(f"Samples captured: {nsamp}")

    read_bin_and_plot(outfile)

if __name__ == "__main__":
    main()
