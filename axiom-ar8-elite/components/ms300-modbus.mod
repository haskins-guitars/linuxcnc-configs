/*
The format of the channel descriptors is:

{TYPE, FUNC, ADDR, COUNT, pin_name}

TYPE is one of HAL_BIT, HAL_FLOAT, HAL_S32, HAL_U32
FUNC = 1, 2, 3, 4, 5, 6, 15, 16 - Modbus commands
COUNT = number of coils/registers to read
*/

#define DEBUG 3
#define MAX_MSG_LEN 16   // may be increased if necessary to max 251

static const hm2_modbus_chan_descriptor_t channels[] = {
    {HAL_U32,   6,   0x2000, 1,     "operation-command"},
    {HAL_FLOAT, 6,   0x2001, 1,     "frequency-command"},
    {HAL_U32,   6,   0x2002, 1,     "fault-command"},
    {HAL_U32,   3,   0x2100, 1,     "fault-status"},
    {HAL_U32,   3,   0x2101, 1,     "operation-status"},
    {HAL_U32,   3,   0x2103, 1,     "output-frequency"},
    {HAL_U32,   3,   0x210B, 1,     "output-torque"},
};