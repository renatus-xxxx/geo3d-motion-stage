set save_settings_on_exit false
set pause_on_lost_focus false
set throttle true
set speed 100
set minframeskip 0
set maxframeskip 0
set vsync off
set fullscreen false
if {[info exists ::env(MOTION_VDP)] && $::env(MOTION_VDP) eq "external"} {
    after time 1 {set ::videosource V9968}
}
