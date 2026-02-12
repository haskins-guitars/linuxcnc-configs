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
            self.set_errormsg("M6: no tool prepared")
            return INTERP_ERROR
        if self.cutter_comp_side:
            self.set_errormsg("Cannot change tools with cutter radius compensation on")
            return INTERP_ERROR
        
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

        do_drop = self.current_tool > 0 and self.current_tool != self.selected_tool
        drop_xy = get_pocket_xy(self, rc_current_pocket)

        self.params["rc_do_drop"] = 1 if do_drop else 0
        self.params["rc_drop_x"] = drop_xy[0]
        self.params["rc_drop_y"] = drop_xy[1]

        do_pickup = self.selected_tool > 0 and self.current_tool != self.selected_tool
        pickup_xy = get_pocket_xy(self, rc_selected_pocket)
        self.params["rc_do_pickup"] = 1 if do_pickup else 0
        self.params["rc_pickup_x"] = pickup_xy[0]
        self.params["rc_pickup_y"] = pickup_xy[1]

        do_probe = self.selected_tool != 0
        self.params["rc_do_probe"] = 1 if do_probe else 0

        return INTERP_OK
    except Exception as e:
        self.set_errormsg("M6/change_prolog: %s" % (e))
        return INTERP_ERROR