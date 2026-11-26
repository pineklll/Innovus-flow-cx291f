read_db ./dbs/03_place.enc/

##opt mode
set_db opt_skew false
set_db opt_skew_ccopt none
set_db opt_max_length 200

##CTS Settings
set_db cts_use_inverters true
set_db cts_max_fanout 16
set_db cts_target_skew 0.2
set_db cts_target_max_transition_time 0.08


set_db cts_inverter_cells [list \
CLKINVX6AL9 \
CLKINVX8AL9 \
CLKINVX12AL9 \
CLKINVX16AL9 \
]


create_route_rule -name cts_leaf \
                  -width_multiplier {M4:M6 1} \
                  -spacing_multiplier {M4:M6 2} \
                  -generate_via

create_route_rule -name cts_2w2s \
                  -width_multiplier {M4:M6 2} \
                  -spacing_multiplier {M4:M6 2} \
                  -generate_via
create_route_type -name cts_top \
                  -bottom_preferred_layer M5 \
                  -top_preferred_layer M6 \
                  -route_rule cts_2w2s
create_route_type -name cts_trunk \
                  -bottom_preferred_layer M5 \
                  -top_preferred_layer M6 \
                  -route_rule cts_2w2s
create_route_type -name cts_leaf_type \
                  -bottom_preferred_layer M4 \
                  -top_preferred_layer M5 \
                  -route_rule cts_leaf


set_db cts_top_fanout_threshold 100		 
eval_legacy "set_ccopt_property routing_top_min_fanout 100"
set_db cts_route_type_top cts_top
set_db cts_route_type_trunk cts_trunk
set_db cts_route_type_leaf cts_leaf_type


# Uncertainty Adjustment
set_interactive_constraint_modes [get_db constraint_modes -if {.is_active == true}]
set_clock_uncertainty 0.300 [get_clocks {Int_clk}]
set_clock_uncertainty 0.050 [get_clocks {Int_clk}] -hold
set_interactive_constraint_modes {}

create_clock_tree_spec -out_file clock.spec
source clock.spec
set_db skew_group:Int_clk/func .cts_skew_group_target_insertion_delay 0.2

clock_opt_design -report_prefix cts -report_dir ./rpt

report_skew_groups -summary

gui_ctd_open

write_db ./dbs/04_cts.enc/

set_db opt_drv true
set_db opt_hold_allow_resize true
set_db opt_hold_cells [list BUFX05AR9 BUFX1AR9]
set_db opt_hold_target_slack 0
set_db opt_setup_target_slack 0.01


opt_design -post_cts -hold -report_dir rpt -report_prefix post_cts

write_db ./dbs/04_post_cts_hold.enc/


exit
