# LinuxCNC RapidChange Configuration

Unofficial LinuxCNC configuration for RapidChangeATC tool changer.

Includes an M6 remap, so normal `Tx M6` commands will use RapidChange ATC.

## Usage

The Px value from the tooltable is used to determine which RapidChange pocket to load/unload a tool from. Other tooltable values are loaded normally.

Tools with Px values less than 1 or greater than `[RAPIDCHANGEATC].NUM_POCKETS` will trigger a manual tool change request.

Example minimal tool table for an 8 pocket changer.

```
TODO: Insert tool table example
```

## Installation

Copy all files to `rapidchange` directory in your configuration.

### `.ini` file `[RAPIDCHANGEATC]`

Add `RAPIDCHANGEATC` section and set values for your machine.

```
[RAPIDCHANGEATC]
NUM_POCKETS = 8

# Position of pocket #1
POCKET_BASE_X = 583
POCKET_BASE_Y = 99.5

# Distance between pockets (can be negative values)
POCKET_OFFSET_X = 0
POCKET_OFFSET_Y = 45

# Before any XY moves, will G53 G0 Z[#<_ini[RAPIDCHANGEATC]SAFE_Z>] to avoid collisions
SAFE_Z = 195

# RPM when loading
ENGAGE_LOAD_RPM = 1500
# Number of strikes during loading, usually 2, but 3 ok.
ENGAGE_LOAD_STRIKES = 2
# RPM when unloading, usually 300RPM higher than load
ENGAGE_UNLOAD_RPM = 1800
# Number of strikes during unloading, usually 1
ENGAGE_UNLOAD_STRIKES = 1

# Machine Z where nut breaks IR, or nut flush with top of changer
ENGAGE_Z_START = 85
# Machine Z at bottom of engage cycle
#  30mm from top of changer
#  ~34mm from IR break
ENGAGE_Z_END = 55
# Feed rate when engaging changer
ENGAGE_Z_FEED = 2000

# motion.digital-in-xx connected to IR sensor
#   -1 disables IR
IR_DI = 0
# motion.digital-out-xx connected to cover output
#   -1 disables cover
COVER_DO = 0

# Toolsetter position
TOOLSET_X = 582.5
TOOLSET_Y = 55

# Feed rate when searching for end of tool
TOOLSET_SEARCH_FEED = 200
# Max distance to search (negative value on most machines)
TOOLSET_SEARCH_DISTANCE = -100
# Backoff distance from search contact to begin latch probe (positive value on most machines)
TOOLSET_LATCH_BACKOFF = 1
# Feed rate when doing more precise latch probe
TOOLSET_LATCH_FEED = 10
# Max distance to do latch probe, should be a little more than (negative value on most machines)
TOOLSET_LATCH_DISTANCE = -1.5
# Machine Z when nut would contact tool setter, used to calculate tool offset
TOOLSET_HEIGHT = 83

# Position to rapid to for manual tool changes
MANUAL_CHANGE_X = 582.5
MANUAL_CHANGE_Y = 0
```

### `.ini` file `[RS274NGC]`

Add remap and subroutines to your existing `[RS274NGC]` section.

```
[RS274NGC]
REMAP=M6    modalgroup=6 prolog=rapidchange_change_prolog ngc=rapidchange_m6 epilog=change_epilog
SUBROUTINE_PATH = \
    rapidchange/subroutines\
    :~/linuxcnc/nc_files/remap-subroutines\
ON_ABORT_COMMAND=o<on_abort> call
```

### `.ini` file `[Python]`

#### If you don't have an existing `[Python]` section

1. Add this to your `.ini` file.

```
[PYTHON]
TOPLEVEL = rapidchange/toplevel.py
PATH_PREPEND = ./rapidchange/python
PATH_PREPEND = ./rapidchange
PATH_APPEND = ~/linuxcnc/nc_files/examples/remap_lib/python-stdglue
```

#### If you have an existing `[Python]` section

1. Merge the contents of `toplevel.py` and `remap.py` into your existing Python code.
2. Add `PATH_PREPEND = ./rapidchange` to your `[Python]` section.
3. Add `PATH_APPEND = ~/linuxcnc/nc_files/examples/remap_lib/python-stdglue` to your `[Python]` section if it doesn't already exist.

### `.ini` file `[HAL]`

Add `[HAL]HALFILE = rapidchange/atc.hal`, and `[HAL]TWOPASS = on` if you're using `or2` anywhere else.

```
[HAL]
HALUI = halui
TWOPASS = on
HALFILE = main.hal
HALFILE = rapidchange/atc.hal
```

### HAL configuration

Update `rapidchange/atc.hal` to:

1. Connect IO nets
    - IR (`rapidchange-dust-cover`)
    - Dust cover(`rapidchange-dust-cover`)
    - Tool setter to correct IO pins (`rapidchange-toolsetter`)
2. If using tool setter, connect `rapidchange-toolsetter` to `motion.probe-input`

```
# If no other probes

net rapidchange-toolsetter motion.probe-input

# If other probes

loadrt or2 names=probes
addf or2 servo-thread
net rapidchange-toolsetter  or2.in0
net other-probe             or2.in1
net any-probe               or2.out => motion.probe-input
```
