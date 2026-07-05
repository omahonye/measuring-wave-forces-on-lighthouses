# Embedded Software

This directory contains the software executed directly on the embedded hardware used during the experimental programme.

## Arduino

The Arduino Uno interfaces with the HX711 load cell amplifier, samples the load cell and transmits force measurements over USB serial.

## Raspberry Pi Pico

The Raspberry Pi Pico interfaces with the accelerometer, samples acceleration measurements and transmits the data over USB serial.

Both devices output a continuous serial stream that is recorded by the Python acquisition software.
