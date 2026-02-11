from interpreter import *
import emccanon

def M6_remap(self, **words):
    if self.task == 0:
        yield INTERP_OK
        return

    # check spindle stopped & tool comp off

    # save current position and settings
    # move to safe Z
    # move to safe X/Y
    # open dust cover, wait 1-2 seconds

    # if same tool, probe length, then continue
    # if has tool, drop tool
    # if next tool, pickup tool, measure tool

    # move to safe Z
    # move to safe X/Y

    # close dust cover

    # return to original X/Y
    # return to original Z (what if that would exceed Z limits with new tool?)

    yield INTERP_OK

def drop_tool(self, atc_pocket) {
    # move to pocket X/Y
    # move to engage start Z
    # start spindle
    # move to engage stop Z
    # dwell briefly
    # stop spindle
    # raise to IR check Z
    # check nut removed
    # raise to safe Z
}

def pickup_tool(self, atc_pocket) {
    # move to pocket X/Y
    # loop to engage_count
        # move to engage start Z
        # start spindle
        # move to engage stop Z
        # dwell briefly
        # stop spindle
    # raise to IR check Z
    # check nut removed
    # raise to safe Z
}