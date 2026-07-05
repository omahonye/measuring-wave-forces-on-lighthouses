#include <HX711_ADC.h>

// HX711 wiring configuration
// dout = data output pin from HX711
// sck  = clock pin to HX711
const int HX711_dout = 4;
const int HX711_sck  = 5;

// Create HX711 object (LoadCell)
HX711_ADC LoadCell(HX711_dout, HX711_sck);

void setup() {
  // Start serial communication for debugging / data output
  Serial.begin(57600);

  // Initialize HX711 and internal variables
  LoadCell.begin();

  // The load cell needs a short time to settle after power-up.
  // During this time, readings may drift.
  unsigned long stabilizingtime = 2000; // milliseconds (2 seconds)

  // Start the HX711:
  // waits for stabilization time
  // performs a tare (zeroing) automatically
  LoadCell.start(stabilizingtime, true);

  // Check if tare operation failed (e.g., wiring issue or no signal)
  if (LoadCell.getTareTimeoutFlag()) {
    Serial.println("ERROR: Tare failed (check wiring or HX711)");
    while (1); // stop program execution
  }

  // This determines how raw readings are scaled.
  // Setting to 1.0 means:
  // output is essentially uncalibrated units (not grams/kg)
  // useful for debugging or calibration process
  LoadCell.setCalFactor(1.0);

  Serial.println("Startup complete. Load cell ready.");
}

void loop() {

  // update() must be called continuously.
  // It returns true when a new measurement is ready.
  if (LoadCell.update()) {

    // getData() returns the current reading:
    // filtered (smoothed) value
    // scaled using calibration factor
    // NOTE: This is NOT the raw 24-bit ADC value.
    float value = LoadCell.getData();

    // Send value to Serial Monitor / Plotter
    Serial.println(value);
  }

  // tareNoDelay() runs in the background.
  // This confirms when it is complete.
  if (LoadCell.getTareStatus()) {
    Serial.println("Tare complete");
  }

  // Send 't' from Serial Monitor to re-zero the scale
  if (Serial.available() > 0) {
    char c = Serial.read();

    if (c == 't') {
      // Start tare without blocking program execution
      LoadCell.tareNoDelay();
      Serial.println("Tare started...");
    }
  }
} 
