import serial
import csv
import time
import matplotlib.pyplot as plt

# ================= USER SETTINGS =================
PORT = "/dev/cu.usbmodem101"
BAUD = 57600
FS = 20
CAPTURE_SECONDS = 30

# ---- CALIBRATION ----
OFFSET = 0
SCALE = 7511
DT = 1.0 / FS
G_TO_N = 9.80665 / 1000.0

# ================= FILE NAME INPUT =================
name = input("Enter test name (e.g. SCO22): ").strip()
CSV_FILE = f"{name}.csv"

# ================= SERIAL =================
ser = serial.Serial(PORT, BAUD, timeout=1)
time.sleep(2)
ser.reset_input_buffer()

# ================= CAPTURE =================
times = []
forces_N = []

with open(CSV_FILE, "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["t_s", "raw", "g", "N"])

    print("Waiting for first data...")

    # ---- WAIT FOR FIRST VALID VALUE ----
    last_raw = None
    while last_raw is None:
        if ser.in_waiting:
            line = ser.readline().decode().strip()
            try:
                last_raw = float(line)
            except:
                pass

    print("Data started — capturing now")

    start_time = time.time()
    next_sample_time = start_time

    try:
        while (time.time() - start_time) < CAPTURE_SECONDS:

            if ser.in_waiting:
                line = ser.readline().decode().strip()
                try:
                    last_raw = float(line)
                except:
                    pass

            now = time.time()

            if now >= next_sample_time:
                t = now - start_time

                grams = (last_raw - OFFSET) / SCALE
                force_N = grams * G_TO_N

                times.append(t)
                forces_N.append(force_N)

                writer.writerow([round(t,4), last_raw, grams, force_N])

                print(f"{t:.2f}s | {force_N:.4f} N")

                next_sample_time += DT

    except KeyboardInterrupt:
        print("Stopped early")
        
ser.close()
print(f"Saved to {CSV_FILE}")

# ================= PLOT =================
if times:
    plt.figure(figsize=(10,5))
    plt.plot(times, forces_N, marker='o')
    plt.xlabel("Time (s)")
    plt.ylabel("Force (N)")
    plt.title(f"Force vs Time ({name})")
    plt.grid(True)
    plt.tight_layout()
    plt.show()
