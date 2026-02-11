import pprint
import emccanon
from interpreter import *
from emccanon import MESSAGE
throw_exceptions = 1

# REMAP=M6  modalgroup=6 prolog=change_prolog ngc=change epilog=change_epilog
# exposed parameters:
#    #<tool_in_spindle>
#    #<selected_tool>
#    #<current_pocket>
#    #<selected_pocket>

def rapidchange_change_prolog(self, **words):
    try:
        if self.selected_pocket < 0:
            self.set_errormsg("M6: no tool prepared")
            return INTERP_ERROR
        if self.cutter_comp_side:
            self.set_errormsg("Cannot change tools with cutter radius compensation on")
            return INTERP_ERROR
        self.params["tool_in_spindle"] = self.current_tool
        self.params["selected_tool"] = self.selected_tool
        self.params["current_pocket"] = self.current_pocket
        self.params["selected_pocket"] = self.selected_pocket

        for tool in self.tool_table:
            if tool.toolno > 0:
                print(pprint.pp(tool))
                print("tool = %i" % tool.toolno)
                print("dia = %i" % tool.diameter)
                print("pocket = %i" % self.find_tool_pocket(tool.toolno)[1])

        return INTERP_OK
    except Exception as e:
        self.set_errormsg("M6/change_prolog: %s" % (e))
        return INTERP_ERROR