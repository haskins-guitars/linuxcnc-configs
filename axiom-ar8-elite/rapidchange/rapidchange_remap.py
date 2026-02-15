import pprint
import os
import linuxcnc
from interpreter import *
from emccanon import MESSAGE
throw_exceptions = 1

class RapidChangeConfig:
    def __init__(self):
        self.inifile = linuxcnc.ini(os.environ['INI_FILE_NAME'])

        self.POCKET_BASE_X = self.read_ini_value("POCKET_BASE_X")
        self.POCKET_BASE_Y = self.read_ini_value("POCKET_BASE_Y")
        self.POCKET_OFFSET_X = self.read_ini_value("POCKET_OFFSET_X")
        self.POCKET_OFFSET_Y = self.read_ini_value("POCKET_OFFSET_Y")
        self.NUM_POCKETS = self.read_ini_value("NUM_POCKETS")

        print(pprint.pp(vars(self)))
    
    def read_ini_value(self, key):
        val = self.inifile.find("RAPIDCHANGEATC", key)
        if val is None:
            raise ValueError("Couldn't find RAPIDCHANGEATC.%s", key)
        return float(val)

def init_rapidchange(self):
    self.rapidchange = RapidChangeConfig()

def get_pocket_xy(self, pocket):
    x = self.rapidchange.POCKET_BASE_X + self.rapidchange.POCKET_OFFSET_X * (pocket - 1)
    y = self.rapidchange.POCKET_BASE_Y + self.rapidchange.POCKET_OFFSET_Y * (pocket - 1)

    return (x, y)

# REMAP=M6  modalgroup=6 prolog=rc_change_prolog ngc=change epilog=change_epilog
# parameters required for epilog:
#    #<tool_in_spindle>
#    #<selected_tool>
#    #<current_pocket>
#    #<selected_pocket>
#
# parameters required for remap ngc
#
#

def rapidchange_change_prolog(self, **words):
    try:
        if self.selected_pocket < 0:
            self.set_errormsg("M6: No tool prepared")
            return INTERP_ERROR
        
        if self.cutter_comp_side:
            self.set_errormsg("M6: Cutter radius compensation must be off")
            return INTERP_ERROR

        # if self.spindle_turning[0] != CANON_DIRECTION.CANON_STOPPED:
        #     self.set_errormsg("M6: Spindle must be stopped")
        #     return INTERP_ERROR
        
        # Required for default epilog
        self.params["tool_in_spindle"] = self.current_tool
        self.params["selected_tool"] = self.selected_tool
        self.params["current_pocket"] = self.current_pocket
        self.params["selected_pocket"] = self.selected_pocket

        # Rapidchange params
        rc_current_pocket = self.find_tool_pocket(self.current_tool)[1]
        # if (rc_current_pocket[0] != 0):
        #     raise ValueError("Current tool pocket not found %i" % self.current_tool)
        
        rc_selected_pocket = self.find_tool_pocket(self.selected_tool)[1]
        # if (rc_current_pocket[0] != 0):
        #     raise ValueError("Selected tool pocket not found %i" % self.selected_tool)
        
        self.params["rc_current_pocket"] = rc_current_pocket
        self.params["rc_selected_pocket"] = rc_selected_pocket

        current_tool_in_rc = \
            rc_current_pocket > 0 \
            and rc_current_pocket <= self.rapidchange.NUM_POCKETS
        
        do_rc_drop = \
            self.current_tool > 0 \
            and current_tool_in_rc \
            and self.current_tool != self.selected_tool
        
        do_manual_drop = \
            self.current_tool > 0 \
            and not current_tool_in_rc \
            and self.current_tool != self.selected_tool
        
        drop_xy = get_pocket_xy(self, rc_current_pocket)

        self.params["rc_do_rc_drop"] = 1 if do_rc_drop else 0
        self.params["rc_do_manual_drop"] = 1 if do_manual_drop else 0
        self.params["rc_drop_x"] = drop_xy[0]
        self.params["rc_drop_y"] = drop_xy[1]

        selected_tool_in_rc = \
            rc_selected_pocket > 0 \
            and rc_selected_pocket <= self.rapidchange.NUM_POCKETS
        
        do_rc_pickup = \
            self.selected_tool > 0 \
            and selected_tool_in_rc \
            and self.current_tool != self.selected_tool
        
        do_manual_pickup = \
            self.selected_tool > 0 \
            and not selected_tool_in_rc \
            and self.current_tool != self.selected_tool
        
        pickup_xy = get_pocket_xy(self, rc_selected_pocket)
        self.params["rc_do_rc_pickup"] = 1 if do_rc_pickup else 0
        self.params["rc_do_manual_pickup"] = 1 if do_manual_pickup else 0
        self.params["rc_pickup_x"] = pickup_xy[0]
        self.params["rc_pickup_y"] = pickup_xy[1]

        do_probe = self.selected_tool != 0
        self.params["rc_do_probe"] = 1 if do_probe else 0

        do_any_action = \
            do_rc_drop or do_manual_drop \
            or do_rc_pickup or do_rc_pickup \
            or do_probe 
        
        self.params["rc_do_any_action"] = 1 if do_any_action else 0

        return INTERP_OK
    except Exception as e:
        self.set_errormsg("M6/raidchange_change_prolog: %s" % (e))
        return INTERP_ERROR