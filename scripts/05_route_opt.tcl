read_db ./dbs/04_post_cts_hold.enc/

set_db design_flow_effort extreme
set_db extract_rc_engine post_route
set_db extract_rc_effort_level high
set_db opt_hold_allow_setup_tns_degradation false
set_db opt_hold_cells {BUFX05AR9 BUFX1AR9}

###add tie cell
set_dont_use TIE1X4CR9  false
set_dont_use TIE0X4CR9  false
set_db add_tieoffs_cells {TIE0X4CR9 TIE1X4CR9}
set_db add_tieoffs_max_fanout 20
set_db add_tieoffs_max_distance 20
add_tieoffs -prefix TIE


# Uncertainty Adjustment
set_interactive_constraint_modes [get_db constraint_modes -if {.is_active == true}]
set_clock_uncertainty 0.150 [get_clocks {Int_clk}]
set_clock_uncertainty 0.050 [get_clocks {Int_clk}] -hold
set_interactive_constraint_modes {}

# route + opt setup #1
route_opt_design -report_prefix route_opt -report_dir ./rpt -setup 
write_db ./dbs/05_route_opt.enc/

# opt config
set_analysis_view \
-setup [list func_libs_ss_c_worst] \
-hold [list func_libs_ff_c_best] 

set_interactive_constraint_modes [get_db constraint_modes -if {.is_active == true}]
set_clock_uncertainty 0.150 [get_clocks {Int_clk}]
set_clock_uncertainty 0.040 [get_clocks {Int_clk}] -hold
set_interactive_constraint_modes {}


# opt setup #2
opt_design -post_route -report_dir rpt -report_prefix post_route_setup_2  -setup 

# opt hold #3
opt_design -post_route -report_dir rpt -report_prefix post_route_hold_3  -hold 

# opt setup + hold #4
opt_design -post_route -report_dir rpt -report_prefix post_route_setup_hold_4 -setup -hold

# timing for full analysis views
set_db timing_enable_simultaneous_setup_hold_mode true
time_design -post_route -report_dir rpt -report_prefix final -expanded_views
set_db timing_enable_simultaneous_setup_hold_mode false

check_connectivity -ignore_weak_connects -ignore_soft_pg_connects -ignore_dangling_wires
delete_drc_markers
check_drc -limit 0

write_db ./dbs/06_route_opt_final.enc
exit
