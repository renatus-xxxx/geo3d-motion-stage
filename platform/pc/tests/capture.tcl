set renderer none
set throttle false
set sound_driver null
set save_settings_on_exit false
set armed 0
set address 0
set trace [open $env(PSG_TRACE_FILE) w]
debug set_watchpoint write_io 160 {} {set ::address $::wp_last_value}
debug set_watchpoint write_io 161 {$::armed} {puts $::trace [format "%02x %02x" $::address $::wp_last_value]}
debug set_watchpoint write_io 47 {} {
 if {$::wp_last_value==85} {set ::armed 1}
 if {$::wp_last_value==170} {close $::trace;exit}
}
after realtime 20 {close $::trace;exit}
