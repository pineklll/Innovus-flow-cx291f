# Innovus Physical Design Flow — example1Sram

A six-stage Cadence **Innovus 25.10 (Stylus mode)** RTL-to-GDS flow for
`example1Sram` on the HL055P 55 nm, 7-metal (M1–M6 + RDL) process. The design
contains one SRAM macro (`mem55lpw128d16sp`) and is clocked by `Int_clk`
(3 ns period).

The flow is driven by the top-level `Makefile`; each stage is one Innovus
process that reads the previous stage's database from `dbs/`.

## Flow

| Stage | Script | Reads | Writes |
|---|---|---|---|
| init | `scripts/01_init.tcl` | LEFs, `mmmc.tcl`, netlist | `dbs/01_init.enc` |
| floorplan + PG | `scripts/02_floorplan_pg.tcl` | `01_init.enc`, `fp.def` | `dbs/02_floorplan.enc`, `dbs/02_floorplan_pg.enc` |
| place | `scripts/03_place.tcl` | `02_floorplan_pg.enc` | `dbs/03_place.enc` |
| CTS | `scripts/04_cts.tcl` | `03_place.enc` | `dbs/04_cts.enc`, `dbs/04_post_cts_hold.enc` |
| route + opt | `scripts/05_route_opt.tcl` | `04_post_cts_hold.enc` | `dbs/05_route_opt.enc`, `dbs/06_route_opt_final.enc` |
| chipfinish | `scripts/06_chipfinish.tcl` | `06_route_opt_final.enc` | `dbs/07_final.enc`, `outputs/` |

`scripts/mmmc.tcl` defines the two MMMC corners/views:

- setup: `ss / 1.08 V / 125 C / cworst` → `func_libs_ss_c_worst`
- hold: `ff / 1.32 V / −40 C / cbest` → `func_libs_ff_c_best`

## Requirements

- Cadence Innovus 25.10 with the Stylus common UI (`innovus -stylus`).
- The course/library tree mounted at `/mnt/nfs_share/EE291F` and
  `/mnt/sharefile/EE291F` (LEF, `.lib`, QRC tech, netlist, SDC, GDS map).
  These absolute paths are hard-coded in `scripts/01_init.tcl`,
  `scripts/mmmc.tcl` and `scripts/06_chipfinish.tcl`; adapt them to your own
  environment.

## Usage

```bash
make init_design   # 01_init
make floorplan     # 02_floorplan_pg
make place_opt     # 03_place
make cts           # 04_cts
make route_opt     # 05_route_opt
make chipfinish    # 06_chipfinish
```

`make chipfinish` runs the entire flow. The targets double as marker files
(`init_design`, `floorplan`, …), so a stage is skipped when its marker exists.
To re-run a stage, remove its marker and the markers of all later stages:

```bash
rm -f place_opt cts route_opt chipfinish
make place_opt
```

Run a single stage directly (must be run from the repository root, because the
scripts use relative paths):

```bash
innovus -stylus -log ./logs/03_place -files ./scripts/03_place.tcl -cpus 16
```

Interactive debugging: `innovus -stylus`, then `read_db dbs/02_floorplan_pg.enc`.

## Results

- `logs/<stage>.log` — tool log; also `.logv` (verbose) and `.cmd` (commands).
- `rpt/` — timing/DRC/connectivity reports (`*.summary.gz`, `*_<Group>.tarpt.gz`,
  `final_check_drc.rpt`, `final_power.rpt`, …). These are gzip-compressed text;
  inspect with `zcat`/`zless`, not `tar`.
- `outputs/` — final netlist (`*.v`, `*_pv.v`), `*.mmmc`, `*.def.gz`, `*.gds`,
  and one SPEF per RC corner.

## Notes

- `fp.def` is a floorplan **input** (manually adjusted SRAM placement and pin
  assignments), read by `scripts/02_floorplan_pg.tcl`.
- `scripts/04_cts.tcl` calls `gui_ctd_open` (clock-tree debugger GUI); remove or
  guard it for headless runs.
- Databases, logs, reports and stage markers are generated artifacts and are
  excluded from version control; see `.gitignore`.

## License

Apache License 2.0 — see [LICENSE](LICENSE).