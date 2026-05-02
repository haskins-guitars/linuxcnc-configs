# Shihlin Servo Parameters

As shipped by Axiom, the servos all had very loose tunes. X and Y following errors of over 1mm, Z up to 3mm.

The main issue was "Low Frequency Vibration Supression" which caused following errors proportional to the frequency configured. Disabled by setting `PB32` and `PB34` to 0.

After that was disabled, tuned in Auto-tuning mode, `PA02 = 2` and adjusted speed and position feed-forwards `PB10` and `PB05`.

[Shilin Servo Confiuration Software, SHServo_Soft](./SHServo_Soft_V3.22.6.zip)
