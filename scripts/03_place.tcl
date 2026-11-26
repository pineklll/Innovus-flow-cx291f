read_db dbs/02_floorplan_pg.enc/

##drv&uncertainty settings
set_interactive_constraint_modes [get_db constraint_modes -if {.is_active == true}]
set_max_fanout 20 [current_design]
set_db opt_fix_fanout_load true
set_clock_uncertainty -setup  0.45 [all_clocks]
set_clock_uncertainty -hold  0.05 [all_clocks]
set_interactive_constraint_modes {}


##design flow settings
set_db design_process_node 55
set_db design_flow_effort standard
set_db design_cong_effort medium
set_db design_power_effort none
set_db design_early_clock_flow false
set_db design_top_routing_layer M5
set_db design_bottom_routing_layer M2


## Place Mode Settings
set_db place_global_reorder_scan true
set_db place_global_place_io_pins false
set_db place_global_timing_effort medium
set_db place_global_cong_effort medium

##Opt Mode Settings
set_db opt_skew false
set_db opt_skew_ccopt none
set_db opt_skew_pre_cts false
set_db opt_max_length 200
set_db opt_area_recovery true
set_db opt_power_effort none
set_db opt_setup_target_slack 0.0
set_db opt_hold_target_slack 0.0


##set dont use
set dontuse_ref " \
                *DEL* \
                *FILL* \
                *ANT* \
                *TAP* \
                *CLK* \
                *X20AR9 \
		*X20AL9 \
                *X05AR9 \
		*X05AL9 \
                *TIE0* \
                *TIE1* \
                *G* \
                "
foreach cell $dontuse_ref {
        echo "set_dont_use $cell true"
        set_dont_use $cell true
}


##set analysis type
set_db timing_analysis_type OCV
set_db timing_analysis_cppr both

## DelayCal Mode
set_db delaycal_equivalent_waveform_model propagation

##group path
reset_path_group -all

set inp     [all_inputs  -no_clocks]
set outp    [all_outputs]
set mems    [get_db insts -if {.base_cell.class == block}]
set regs    [remove_from_collection [all_registers -edge_triggered] $mems]
set allregs [all_registers]


# Create IO Path Groups
group_path -name In2Reg        -from $inp        -to $allregs
group_path -name Reg2Out       -from $allregs    -to $outp
group_path -name In2Out        -from $inp        -to $outp

# Create REG Path Groups
group_path -name Reg2Reg       -from $regs       -to $regs
group_path -name Reg2Mem       -from $regs       -to $mems
group_path -name Mem2Reg       -from $mems       -to $regs
group_path -name Mem2Mem       -from $mems       -to $mems

# Increasing the optimizer effort on the paths using path groups:
set_path_group_options In2Reg       -effort_level low -weight 5
set_path_group_options Reg2Out      -effort_level low -weight 5
set_path_group_options In2Out       -effort_level low -weight 5
set_path_group_options Reg2Reg      -effort_level high -weight 10
set_path_group_options Reg2Mem      -effort_level high -weight 10
set_path_group_options Mem2Reg      -effort_level high -weight 10
set_path_group_options Mem2Mem      -effort_level high -weight 10


###place_opt core cmd
place_opt_design -report_prefix place -report_dir ./rpt

###add tie cell
set_dont_use TIE1X4CR9  false
set_dont_use TIE0X4CR9  false
set_db add_tieoffs_cells {TIE0X4CR9 TIE1X4CR9}
set_db add_tieoffs_max_fanout 20
set_db add_tieoffs_max_distance 20
add_tieoffs -prefix TIE

write_db ./dbs/03_place.enc
exit

