POST_NAME = "Axiom AR8 Elite - LinuxCNC - RapidChange (.ngc)"

FILE_EXTENSION = "ngc"

UNITS = "MM"

SUBSTITUTE = "({)}"

+------------------------------------------------
+    Line terminating characters
+------------------------------------------------

LINE_ENDING = "[13][10]"

+------------------------------------------------
+    Block numbering
+------------------------------------------------

LINE_NUMBER_START     = 0
LINE_NUMBER_INCREMENT = 10
LINE_NUMBER_MAXIMUM = 999999

+================================================
+
+    Formating for variables
+
+================================================

VAR LINE_NUMBER = [N|A|N|1.0]
VAR SPINDLE_SPEED = [S|A|S|1.0]
VAR FEED_RATE = [F|C|F|1.1]
VAR X_POSITION = [X|A|X|1.3]
VAR Y_POSITION = [Y|A|Y|1.3]
VAR Z_POSITION = [Z|A|Z|1.3]
VAR ARC_CENTRE_I_INC_POSITION = [I|A|I|1.3]
VAR ARC_CENTRE_J_INC_POSITION = [J|A|J|1.3]
VAR X_HOME_POSITION = [XH|A|X|1.3]
VAR Y_HOME_POSITION = [YH|A|Y|1.3]
VAR Z_HOME_POSITION = [ZH|A|Z|1.3]
VAR SAFE_Z_HEIGHT = [SAFEZ|A|Z|1.3]
VAR DWELL_TIME = [DWELL|A|P|1.2]
+================================================
+
+    Block definitions for toolpath output
+
+================================================

+---------------------------------------------------
+  Commands output at the start of the file
+---------------------------------------------------

begin HEADER

"( [TP_FILENAME] )"
"( File created: [DATE] - [TIME])"
"( for LinuxCNC Axiom AR8 Elite from Vectric )"
"( Material Size)"
"( X= [XLENGTH], Y= [YLENGTH] ,Z= [ZLENGTH])"
"([FILE_NOTES])"
"(Toolpaths used in this file:)"
"([TOOLPATHS_OUTPUT])"
"(Tools used in this file: )"
"([TOOLS_USED])"
"[N] G0 G21 G17 G90 G40 G80 G94"
"[N] G64 P0.01"

"[N] G53 G0 Z194"
"[N] G0 [XH] [YH] [F]"
"[N] G0 [ZH]"

"[N] M5"
"[N] T[T] M6"
"[N] ([TOOLNAME])"
"[N] G43H[T]"

"[N] [S] M03"
"([TOOLPATH_NAME])"
"([TOOLPATH_NOTES])"

+---------------------------------------------------
+  Commands output for rapid moves
+---------------------------------------------------

begin RAPID_MOVE

"[N] G0 [X] [Y] [Z]"


+---------------------------------------------------
+  Commands output for the first feed rate move
+---------------------------------------------------

begin FIRST_FEED_MOVE

"[N] G1 [X] [Y] [Z] [F]"


+---------------------------------------------------
+  Commands output for feed rate moves
+---------------------------------------------------

begin FEED_MOVE

"[N] G1 [X] [Y] [Z]"

+---------------------------------------------------
+  Commands output for the first clockwise arc move
+---------------------------------------------------

begin FIRST_CW_ARC_MOVE

"[N] G2 [X] [Y] [I] [J] [F]"

+---------------------------------------------------
+  Commands output for clockwise arc  move
+---------------------------------------------------

begin CW_ARC_MOVE

"[N] G2 [X] [Y] [I] [J]"

+---------------------------------------------------
+  Commands output for the first counterclockwise arc move
+---------------------------------------------------

begin FIRST_CCW_ARC_MOVE

"[N] G3 [X] [Y] [I] [J] [F]"

+---------------------------------------------------
+  Commands output for counterclockwise arc  move
+---------------------------------------------------

begin CCW_ARC_MOVE

"[N] G3 [X] [Y] [I] [J]"


+---------------------------------------------------
+  Commands output for first clockwise helical arc  moves
+---------------------------------------------------

begin FIRST_CW_HELICAL_ARC_MOVE

"[N] G2 [X] [Y] [Z] [I] [J] [F]"

+---------------------------------------------------
+  Commands output for clockwise helical arc  moves
+---------------------------------------------------

begin CW_HELICAL_ARC_MOVE

"[N] G2 [X] [Y] [Z] [I] [J]"

+---------------------------------------------------
+  Commands output for first counterclockwise helical arc  moves
+---------------------------------------------------

begin FIRST_CCW_HELICAL_ARC_MOVE

"[N] G3 [X] [Y] [Z] [I] [J] [F]"

+---------------------------------------------------
+  Commands output for counterclockwise helical arc  moves
+---------------------------------------------------

begin CCW_HELICAL_ARC_MOVE

"[N] G3 [X] [Y] [Z] [I] [J]"

+---------------------------------------------------
+  Commands output for first clockwise helical arc plunge moves
+---------------------------------------------------

begin FIRST_CW_HELICAL_ARC_PLUNGE_MOVE

"[N] G2 [X] [Y] [Z] [I] [J] [F]"

+---------------------------------------------------
+  Commands output for clockwise helical arc plunge moves
+---------------------------------------------------

begin CW_HELICAL_ARC_PLUNGE_MOVE

"[N] G2 [X] [Y] [Z] [I] [J]"

+---------------------------------------------------
+  Commands output for first counter clockwise helical arc plunge moves
+---------------------------------------------------

begin FIRST_CCW_HELICAL_ARC_PLUNGE_MOVE

"[N] G3 [X] [Y] [Z] [I] [J] [F]"

+---------------------------------------------------
+  Commands output for counter clockwise helical arc plunge moves
+---------------------------------------------------

begin CCW_HELICAL_ARC_PLUNGE_MOVE

"[N] G3 [X] [Y] [Z] [I] [J]"


+---------------------------------------------------
+  Commands output at toolchange
+---------------------------------------------------

begin TOOLCHANGE

"[N] G0 [SAFEZ]"
"[N] M5"
"[N] T[T] M6"
"[N] ([TOOLNAME])"
"[N] G43H[T]"


+---------------------------------------------------
+  Commands output for a new segment - toolpath
+  with same toolnumber but maybe different feedrates
+---------------------------------------------------

begin NEW_SEGMENT

"[N] [S] M03"
"([TOOLPATH_NAME])"
"([TOOLPATH_NOTES])"

+---------------------------------------------
+  Commands output for a dwell move
+---------------------------------------------

begin DWELL_MOVE

"G4 [DWELL]"


+---------------------------------------------------
+  Commands output at the end of the file
+---------------------------------------------------

begin FOOTER

"[N] G0 [ZH]"
"[N] G0 [XH] [YH]"
"[N] G53 G0 Z194"
"[N] M09"
"[N] M30"
%
