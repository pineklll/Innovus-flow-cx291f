proc get_nets_from_drc_violations {{skip_pg_net 0} {in_file {}}} {
  set n_list {}
  set fd ""

  if {[string length $in_file] > 0} {
    set fd [open $in_file w]
  }

 
  foreach mkr [get_db markers -if {.subtype == "Metal_Short"}] {
    set msg [get_db $mkr .message]
    
    
    if {([regexp {Regular Wire of Net (\S+)} $msg junk str1] || [regexp {Regular Via of Net (\S+)} $msg junk str1])} {
      set net_obj [get_nets -quiet $str1]
      if {$net_obj != ""} {
        if {$skip_pg_net == 0 || [get_db $net_obj .is_power] == 0 || [get_db $net_obj .is_ground] == 0 } {
          lappend n_list $str1
        }
      }
    }
  
   regsub {Regular Wire of Net} $msg {} next_msg
   if {[regexp {Regular Wire of Net (\S+)} $next_msg junk str2] || [regexp {Regular Via of Net (\S+)} $next_msg junk str2]} {
      set net_obj2 [get_nets -quiet $str2]
      if {$net_obj2 != ""} {
        if {$skip_pg_net == 0 || [get_db $net_obj2 .isPwrOrGnd] == 0} {
          lappend n_list $str2
        }
      }
    }
  }

  set n_list [lsort -unique $n_list]
  
  if {[llength $n_list] > 0} {
    delete_routes -net $n_list
    route_eco 
  }

  if {$fd != ""} {
    puts $fd $n_list
    close $fd
  }

  return $n_list
}

get_nets_from_drc_violations

