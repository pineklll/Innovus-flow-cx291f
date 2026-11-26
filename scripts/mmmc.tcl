#########################
#File Path Configuration#
#########################
set LIB_PATH "/mnt/nfs_share/EE291F/library/lib"
set SDC_PATH "/mnt/nfs_share/EE291F/input"
set QRC_PATH "/mnt/nfs_share/EE291F/tech/qrc"


set RVT_BEST "${LIB_PATH}/std/RVT/M31GPSC900HL055PR_N40CFF1P32_cbest_ccs.lib.gz"
set RVT_WORST "${LIB_PATH}/std/RVT/M31GPSC900HL055PR_125CSS1P08_cworst_ccs.lib.gz"
set LVT_BEST "${LIB_PATH}/std/LVT/M31GPSC900HL055PL_N40CFF1P32_cbest_ccs.lib.gz"
set LVT_WORST "${LIB_PATH}/std/LVT/M31GPSC900HL055PL_125CSS1P08_cworst_ccs.lib.gz"

set MEM_FF "${LIB_PATH}/mem/mem55lpw128d16sp_ff1p32vn40c.lib"
set MEM_SS "${LIB_PATH}/mem/mem55lpw128d16sp_ss1p08v125c.lib"

set SDC "${SDC_PATH}/example1Sram.sdc"

set QRC_CBEST "${QRC_PATH}/cbest/qrcTechFile"
set QRC_CWORST "${QRC_PATH}/cworst/qrcTechFile"

#####################
#Create Library Sets#
#####################
create_library_set -name libs_ss \
	-timing [list \
		${RVT_WORST} \
		${LVT_WORST} \
		${MEM_SS} \
		]
create_library_set -name libs_ff \
	-timing [list \
		${RVT_BEST} \
		${LVT_BEST} \
		${MEM_FF} \
		]

############################
#Create Operating Condition#
############################
create_opcond -name ff1p32vn40c -process 1 -voltage 1.32 -temperature -40
create_opcond -name ss1p08v125c -process 1 -voltage 1.08 -temperature 125

#########################
#Create Timing Condition#
#########################
create_timing_condition -name ff1p32vn40c_timingcond \
	-library_sets [list libs_ff] \
	-opcond ff1p32vn40c
create_timing_condition -name ss1p08v125c_timingcond \
	-library_sets [list libs_ss] \
	-opcond ss1p08v125c
 
###################
#Create RC Corners#
###################
create_rc_corner -name c_worst -temperature 125 -qrc_tech ${QRC_CWORST}
create_rc_corner -name c_best -temperature -40 -qrc_tech ${QRC_CBEST}

########################
#Create Constraint Mode#
########################
create_constraint_mode -name func -sdc_files ${SDC}

######################
#Create Delay Corners#
######################
create_delay_corner -name libs_ss_c_worst \
	-timing_condition ss1p08v125c_timingcond \
	-rc_corner c_worst
create_delay_corner -name libs_ff_c_best \
	-timing_condition ff1p32vn40c_timingcond \
	-rc_corner c_best

#######################
#Create Analysis Views#
#######################
create_analysis_view -name func_libs_ss_c_worst \
	-constraint_mode func \
	-delay_corner libs_ss_c_worst
create_analysis_view -name func_libs_ff_c_best \
	-constraint_mode func \
	-delay_corner libs_ff_c_best



###########################################################

set_analysis_view -setup [list func_libs_ss_c_worst] \
		  -hold [list func_libs_ff_c_best] 


