extends Node

## Meta / session state — survives scene changes AND run resets (unlike
## RunState, which is wiped when a run is born). For now it only tracks
## whether the title flythrough has already played this session, so
## returning from a death drops straight to the settled menu instead of
## replaying the 16 s walk. Later: the home for banked meta-progression.

var intro_seen := false
