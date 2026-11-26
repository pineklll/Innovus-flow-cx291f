read_db ./dbs/06_route_opt_final.enc/

if {![file exists ./outputs]} {
    file mkdir ./outputs
}

# add filler cells
set_db add_fillers_cells {FILLERC32CR9 FILLERC32CL9 FILLERC16CR9 FILLERC16CL9 FILLERC8CR9 FILLERC8CL9}
add_fillers -prefix DECAP
set_db add_fillers_cells {FILLER32AR9 FILLER32AL9 FILLER16AR9 FILLER16AL9 FILLER8AR9 FILLER8AL9 FILLER4AR9 FILLER4AL9 FILLER3AR9 FILLER3AL9 FILLER2AR9 FILLER2AL9 FILLER1AR9 FILLER1AL9}	
add_fillers -prefix FILLER
check_filler 

connect_global_net VDD -type pgpin -pin_base_name VCCK -all -verbose
connect_global_net VDD -type pgpin -pin_base_name VDD -all -verbose
connect_global_net VDD -type tie_hi -pin_base_name VCCK -all -verbose
connect_global_net VSS -type pgpin -pin_base_name GNDK -all -verbose
connect_global_net VSS -type pgpin -pin_base_name VSS -all -verbose
connect_global_net VSS -type tie_lo -pin_base_name GNDK -all -verbose

# check place & floorplan
check_place > ./rpt/check_place.rpt
check_floorplan > ./rpt/check_floorplan.rpt

# check connectivity & drc
check_connectivity -ignore_soft_pg_connects -ignore_weak_connects -ignore_dangling_wires
check_connectivity -ignore_soft_pg_connects -ignore_weak_connects -ignore_dangling_wires -out_file ./rpt/final_check_connectivity.rpt
check_drc -limit 0
check_drc -limit 0 -out_file ./rpt/final_check_drc.rpt

##use following script to fix drc vios,you need to change the violation type (now the example type is "Metal_Short") to be your real drc type, save the fix_drc.tcl,then source it directly
##./scripts/fix_drc.tcl


# report design summary 
report_summary -no_html -out_file ./rpt/final_design_summary.rpt

# report power
report_power -out_file ./rpt/final_power.rpt

## save final files for signoff steps
write_netlist ./outputs/[get_db designs .name].v
write_netlist ./outputs/[get_db designs .name]_pv.v -include_pg -exclude_leaf_cells
write_mmmc > ./outputs/[get_db designs .name].mmmc
write_def ./outputs/[get_db designs .name].def.gz -netlist -floorplan -routing

# spef file for timing signoff (PT or Tempus)
set_db extract_rc_effort_level signoff
extract_rc
foreach rc_corner [get_db rc_corners .name] {
write_parasitics -spef_file ./outputs/$rc_corner.spef -rc_corner $rc_corner
}


# gds file for physical validation 
set map_file "/mnt/sharefile/EE291F/tech/innovus2gds.map"
set cell_gds [list \
/mnt/nfs_share/EE291F/library/gds/M31GPSC900HL055PR.gds \
/mnt/nfs_share/EE291F/library/gds/M31GPSC900HL055PL.gds \
/mnt/nfs_share/EE291F/library/gds/mem55lpw128d16sp.gds \
] 
write_stream ./outputs/[get_db designs .name].gds  -map_file ${map_file} -merge ${cell_gds}

write_db ./dbs/07_final.enc

exit
