read_db dbs/01_init.enc/

##1.define block size
create_floorplan -die_size  {125.84 95 3.64 3.6 3.64 3.6}
check_floorplan -report_density

##place memory
##2.adjust memory location manually
##3.fix the memory. click the memory firstly, then usind following cmd
set_db selected .place_status fixed


##place pins
#4.place pins manually or you can use following cmds
set_db assign_pins_edit_in_batch true
edit_pin -fix_overlap 1 -unit track -spread_direction clockwise -side left -layer M3 -spread_type start -spacing 5 -start 0 64.1  -pin [get_object_name  [get_ports -filter "direction==in"]]
edit_pin -fix_overlap 1 -unit track -spread_direction counterclockwise -side right -layer M3 -spread_type start -spacing 5 -start 125.84 64.1  -pin [get_object_name [get_ports -filter "direction==out"]]
set_db assign_pins_edit_in_batch false
#5. fix the pins
set_db [get_db ports] .place_status fixed


##6.add halo
create_place_halo -all_blocks -halo_deltas  {3 0 3 5}


##7.read def (mem block placed manually)
##write def is disabled
#set hard_macro [get_db insts -if ".base_cell.class==block"]
#deselect_obj -all
#select_obj $hard_macro
#select_obj [get_db ports]
#write_def -floorplan -selected  fp.def

read_def ./fp.def
# keep the macro fixed after reading the def
set_db [get_db insts -if ".base_cell.class==block"] .place_status fixed

##8.set dont use cell 
set dontuse_ref " \
                *DEL* \
                *FILL* \
                *ANT* \
                *TAP* \
                *CLK* \
                *X20AR9 \
                *X05AR9 \
                *TIE0* \
                *TIE1* \
                *G* \
                "
foreach cell $dontuse_ref {
        echo "set_dont_use $cell true"
        set_dont_use $cell true
}

##9.add tap cell
set_dont_use TAP01CR9 false
add_well_taps -cell TAP01CR9 -cell_interval 50 -prefix WELLTAP -checker_board
set_dont_use TAP01CR9 true


write_db ./dbs/02_floorplan.enc

##10.create power stripe
connect_global_net VDD -type pgpin -pin_base_name VCCK -all -verbose
connect_global_net VDD -type pgpin -pin_base_name VDD -all -verbose
connect_global_net VDD -type tie_hi -pin_base_name VCCK -all -verbose
connect_global_net VSS -type pgpin -pin_base_name GNDK -all -verbose
connect_global_net VSS -type pgpin -pin_base_name VSS -all -verbose
connect_global_net VSS -type tie_lo -pin_base_name GNDK -all -verbose 


set_db add_stripes_stacked_via_bottom_layer M1
set_db add_stripes_stacked_via_top_layer M4
add_stripes -nets {VDD VSS} \
            -layer M6 \
	    -direction vertical \
	    -width 6 \
            -spacing 1.5 \
            -set_to_set_distance 30 \
            -start_from left \
            -start_offset 1 \
            -extend_to design_boundary

set_db add_stripes_stacked_via_bottom_layer M5
set_db add_stripes_stacked_via_top_layer M6
add_stripes -nets {VDD VSS} \
            -layer M5 \
	    -direction horizontal \
            -width 6 \
            -spacing 1.5 \
            -set_to_set_distance 30 \
            -start_from bottom \
            -start_offset 1 \
            -extend_to design_boundary

set_db add_stripes_stacked_via_bottom_layer M4
set_db add_stripes_stacked_via_top_layer M5
add_stripes -nets {VDD VSS} \
            -layer M4 \
            -direction vertical \
            -width 1 \
            -spacing 1 \
            -set_to_set_distance 10 \
            -start_from left \
            -start_offset 1 \
            -area {3.64 64.3 122.64 115.2}


route_special -nets {VDD VSS} \
              -connect {block_pin core_pin} \
	      -core_pin_layer M1 \
	      -block_pin_target stripe \
	      -allow_jogging 1 \
	      -allow_layer_change 1

delete_drc_markers
check_drc -limit 0

write_db ./dbs/02_floorplan_pg.enc

exit
