set_db init_power_nets {VDD}
set_db init_ground_nets {VSS}

read_physical -lefs {/mnt/nfs_share/EE291F/tech/HL055P_7M6X1T4_RDL.lef /mnt/nfs_share/EE291F/library/lef/std/M31GPSC900HL055PR.lef /mnt/sharefile/EE291F/library/lef/std/M31GPSC900HL055PL.lef /mnt/nfs_share/EE291F/library/lef/mem/mem55lpw128d16sp.lef}

read_mmmc ./scripts/mmmc.tcl

read_netlist /mnt/nfs_share/EE291F/input/example1Sram_netlist.v

init_design

write_db ./dbs/01_init.enc

exit
