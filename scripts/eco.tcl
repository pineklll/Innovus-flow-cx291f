set_db eco_batch_mode true
set_db eco_honor_dont_touch false
set_db eco_honor_dont_use false
set_db eco_check_logical_equivalence true

eco_update_cell -insts xxx -cells xxx

set_db eco_batch_mode false
set_db eco_honor_dont_touch true
set_db eco_honor_dont_use true
set_db eco_check_logical_equivalence true


place_detail -eco
route_eco
