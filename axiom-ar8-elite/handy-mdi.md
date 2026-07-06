```gcode
; Set G54 (Px) X/Y 0 to current position (X/Y/X relative to current position)
g10 l20 p0 x0 y0

; Clear loaded tool (without ATC unload)
; Qx = tool number to set as current tool
m61 q0

; ATC load tool 24003
t24003 m6

; ATC Unload tool
t0 m6

; Trigger ATC toolset routine
o<toolset> call

```