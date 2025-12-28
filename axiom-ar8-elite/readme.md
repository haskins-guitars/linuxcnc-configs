# Axiom AR8 Elite Linux CNC Conversion

Documentation for conversion from RichAuto B5x controller to LinuxCNC using a Mesa 7i95T IO board.

## Installation

- Clone to `~/linuxcnc/configs/axiom`
- Run `./install.sh` to compile and install modules

## TODO

- Map servo alarm inputs to `joint.N.amp-fault-in`.
- Use servo encoder feedback to do something other than warn on excess error.

## MESA I/O

Outputs

0. Servo Enable
1. Servo Clear Alarm
2. ATC Cover
3. Unused
4. Unused
5. Unused

Inputs

0. X Home
1. X Limit
2. Y Home
3. Y Limit
4. Z Home
5. Tool Setter (Puck)
6. A Home
7. E-Stop
8. Tool setter (ATC)
9. ATC IR
10. Unused
11. Unused
12. Unused
13. Unused
14. Unused
15. Unused
16. Servo X - Alarm
17. Unused
18. Servo Y - Alarm
19. Unused
20. Servo Z - Alarm
21. Unused
22. Unused
23. Unused

Encoders

0. X
1. Y
2. Z

Step/Dir

0. X
1. Y
2. Z
3. A

## Servo Harness

Two CAT 6 cables wired to servo connect at one end, ferruls at the other.

Solid = positive, white = negative in differential pairs

| Cable | Color                 | Signal               | Servo `func (pin)`     | Mesa           |
| ----- | --------------------- | -------------------- | ---------------------- | -------------- |
| 1     | Orange / White Orange | A +/-                | A +/- (33 / 34)        | 7i95 TB1...    |
| 1     | Green / White Green   | B +/-                | B +/- (35 / 36)        | 7i95 TB1...    |
| 1     | Blue / White Blue     | C +/-                | Z +/- (37 / 38)        | 7i95 TB1...    |
| 1     | Brown                 | Servo Alarm          | DO6 (46)               | 7i95 TB5...    |
| 1     | White / Brown         |                      |                        |                |
|       |                       |                      |                        |                |
| 2     | Orange / White Orange | Step +/-             | NP / NG (6 / 5)        | 7i95 TB3...    |
| 2     | Green / White Green   | Dir +/-              | PP/PG (8 / 9)          | 7i95 TB3...    |
| 2     | Blue                  | Servo Enable ()      | DI1 (14)               | Enable TB      |
| 2     | White / Blue          | Clear Servo Alarm () | DI5 (18)               | Clear Alarm TB |
| 2     | Brown                 | GND                  | SG (50)                | 7i95 TB3...    |
| 2     | White / Brown         |                      |                        |                |
|       |                       |                      |                        |                |
|       |                       | DI Common            | VDD (48)-> COM+ (49)   |                |
|       |                       | DO Common            | VDD (48) -> DOCOM (40) |                |

## Servo Drive configuration

- Changed `PD01` from `1111` to `1110`
  - Read `SON`, servo enable, from DI

## VFD Harness

RJ45 connected to VFD's RS485 connection, connected to Mesa serial 0, TB4 13-18.

## VFD Config

VFD is controlled and monitored using a combination of `mesa-modbus`, in `./components/ms300-modbus.mod`, and custom compoents to parse and pack the register data, `./components/ms300\_\*.comp.

HAL configuration is in `spindle.hal`.

- Changed 09-01 from 9.6 (9600 baud) to 115.2 (115200 baud)
- Changed 09.02 from 3 (no fault on comms loss) to 2 (fault and ramp to stop on loss of comms from controllers)
- Changed 09-03 from 0 (don't detect comms fault) to 2.0 (detect timeout after 2 seconds)
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
