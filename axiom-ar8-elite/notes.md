# Axiom AR8 Elite

## TODO

- Servo alarm inputs to `joint.N.amp-fault-in`
- Homing switches

## Servo Drive configuration

- Changed `PD01` from `1111` to `1110`
  - Read `SON`, servo enable, from DI

## VFD Config

- Changed 09-01 from 9.6 to 115.2, 115200 baud
- Changed 09.02 from 3 to 2 (fault and ramp to stop on loss of comms from controllers)
- Changed 09-03 from 0 to 2.0, detect timeout after 2 seconds
- Changed 00-20 from 2 to 1 (485 frequency source)
- Changed 00-21 from 1 to 2 (485 operation source)
- Changed 02-00 from 1 (2-wire) to 0 (disabled)
- Changed 00-23 from 1 (disable reverse) to 0 (allow forward/reverse)
```
# clear reset
setp delta_vfd_modbus.00.fault_command 2

# set scale
setp delta_vfd_modbus.00.frequency_command-scale 0.6

# stop
setp delta_vfd_modbus.00.operation_command 1

# forward
setp delta_vfd_modbus.00.operation_command 6
```