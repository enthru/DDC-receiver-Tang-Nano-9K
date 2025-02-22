
Changes in this fork:

- Change frequency via serial command - just connect to the standart gowin uart and type frequency in the terminal (no checks!).
- Press second button (not reset :)) to show current frequency in the uart terminal.

Test fpga Gowin on module tang-nano-9k as ddc-frontend for sdr eceiver

Structure:
-  12 bit samples from AD9226 (clock 61.440 MHz)
-  cordic => IQ
-  2 stage CIC-decimator
-  polyphaze FIR-decimator X8R8
-  output quadrature samples on MCU over I2S-master interface (48000 Hz sample rate)

Controll fpga over I2C interface (get tune frequency from MCU)
