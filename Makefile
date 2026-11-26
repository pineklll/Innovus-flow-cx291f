###Backend Targets###

init_design:
	innovus -stylus -log ./logs/01_init -files ./scripts/01_init.tcl -cpus 16
	echo "init_design completed in `pwd` `date`" > init_design

floorplan: init_design
	innovus -stylus -log ./logs/02_floorplan_pg -files ./scripts/02_floorplan_pg.tcl -cpus 16
	echo "floorplan completed in `pwd` `date`" > floorplan
	

place_opt: floorplan
	innovus -stylus -log ./logs/03_place -files ./scripts/03_place.tcl -cpus 16
	echo "place_opt completed in `pwd` `date`" > place_opt

cts: place_opt
	innovus -stylus -log ./logs/04_cts  -files ./scripts/04_cts.tcl -cpus 16
	echo "cts completed in `pwd` `date`" > cts

route_opt: cts
	innovus -stylus -log ./logs/05_route_opt  -files ./scripts/05_route_opt.tcl -cpus 16
	echo "route_opt completed in `pwd` `date`" > route_opt

chipfinish: route_opt
	innovus -stylus -log ./logs/06_chipfinish -files ./scripts/06_chipfinish.tcl -cpus 16
	echo "chipfinish completed in `pwd` `date`" > chipfinish
