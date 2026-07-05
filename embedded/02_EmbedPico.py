import machine
import time

# I2C setup (SDA = Pin GP4, SCL = Pin GP5)
i2c = machine.I2C(0, scl=machine.Pin(5), sda=machine.Pin(4), freq=400000)
ADXL345_ADDR = 0x53
G_TO_MS2 = 9.80665  # conversion factor from g to m/s²

def adxl345_init():
    # Confirm sensor is connected
    if ADXL345_ADDR not in i2c.scan():
        print("ERROR: ADXL345 Sensor not connected. Check wiring.")
        while True:
            pass  # Halt program
    
    # Power on: set POWER_CTL (0x2D) to Measure mode (bit 3 = 1)
    i2c.writeto_mem(ADXL345_ADDR, 0x2D, b'\x08')
    
    # Set DATA_FORMAT (0x31): Full resolution, ±2g => 0x08
    i2c.writeto_mem(ADXL345_ADDR, 0x31, b'\x08')

def read_accel():
    data = i2c.readfrom_mem(ADXL345_ADDR, 0x32, 6)
    x_g = int.from_bytes(data[0:2], 'little', signed=True) * 0.004
    y_g = int.from_bytes(data[2:4], 'little', signed=True) * 0.004
    z_g = int.from_bytes(data[4:6], 'little', signed=True) * 0.004
    # Convert to m/s²
    x_ms2 = x_g * G_TO_MS2
    y_ms2 = y_g * G_TO_MS2
    z_ms2 = z_g * G_TO_MS2
    return x_ms2, y_ms2, z_ms2

# Initialize the accelerometer
adxl345_init()

# Sampling rate setup
hertz = 400
delay = int(1000 / hertz)

# Print CSV header
print("timestamp_ms,accel_x_mps2,accel_y_mps2,accel_z_mps2")

# Start logging
start = time.ticks_ms()
try:
    while True:
        timestamp = time.ticks_diff(time.ticks_ms(), start)
        ax, ay, az = read_accel()
        print("{},{:.4f},{:.4f},{:.4f}".format(timestamp, ax, ay, az))
        time.sleep_ms(delay)
except KeyboardInterrupt:
    print("Logging stopped.")
