# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Physical implementation (netlist → GDS) of `example1Sram` on the HL055P 55 nm,
7-metal (M1–M6 + RDL) process, using **Cadence Innovus 25.10 in Stylus mode**
(`set_db`-style commands). The design contains one SRAM macro
(`mem55lpw128d16sp`) and is clocked by `Int_clk` at a 3 ns period.

The flow is a fixed six-stage script chain driven by the top-level `Makefile`;
each stage is one Innovus process that reads the previous stage's database and
writes a new one under `dbs/`. All tech libraries, the netlist, and the SDC are
read from NFS mounts, not from this directory.

## Commands

Run everything from the repository root; the Tcl scripts use relative paths
(`dbs/`, `fp.def`, `clock.spec`, `./rpt`, `./outputs`).

```bash
make init_design   # 01_init.tcl        -> dbs/01_init.enc
make floorplan     # 02_floorplan_pg.tcl -> dbs/02_floorplan.enc, dbs/02_floorplan_pg.enc
make place_opt     # 03_place.tcl       -> dbs/03_place.enc
make cts           # 04_cts.tcl         -> dbs/04_cts.enc, dbs/04_post_cts_hold.enc
make route_opt     # 05_route_opt.tcl   -> dbs/05_route_opt.enc, dbs/06_route_opt_final.enc
make chipfinish    # 06_chipfinish.tcl  -> dbs/07_final.enc, ./outputs/*, ./rpt/*
```

`make chipfinish` runs the entire flow. The targets and the marker files they
touch (`init_design`, `floorplan`, `place_opt`, `cts`, `route_opt`,
`chipfinish`) have the same names, and there is no `.PHONY`: make skips a stage
when its marker file exists. To re-run a stage, delete its marker (and those of
all later stages, which are now stale), then re-run:

```bash
rm -f place_opt cts route_opt chipfinish
make place_opt
```

To run a single stage without make (equivalent to the recipe):

```bash
innovus -stylus -log ./logs/03_place -files ./scripts/03_place.tcl -cpus 16
```

Interactive debug: launch `innovus -stylus` in the repository root and
`read_db dbs/02_floorplan_pg.enc`.

### Verification (no unit tests or linters)

Checks are embedded in the flow: `check_floorplan`, `check_place`,
`check_connectivity` (with `-ignore_soft_pg_connects -ignore_weak_connects
-ignore_dangling_wires`), `check_drc -limit 0`, `report_summary`, and
`report_power`. Inspect:

- `logs/<stage>.log` / `.logv` (verbose) / `.cmd` (echoed commands) — the end
  contains a message summary; e.g. `grep -E "ERROR|Message Summary" logs/*.log`
- `rpt/` — timing/DRC/connectivity reports: `final_check_drc.rpt`,
  `final_check_connectivity.rpt`, `final_design_summary.rpt`, `final_power.rpt`,
  plus `<prefix>.summary.gz` and per-path-group `<prefix>_<Group>.tarpt.gz`
  files. These are **gzip-compressed text**; use `zcat`/`zless`, not `tar`.
- `outputs/` — `<design>.v`, `<design>_pv.v`, `<design>.mmmc`,
  `<design>.def.gz`, `<design>.gds`, and one SPEF per RC corner
- `example1Sram.geom.rpt` — DRC result written by `check_drc` (if produced)

## Flow and database chain

Each script ends with `exit`; no state survives between stages except the
`.enc` database directories. Note that `05_route_opt.tcl` writes
`dbs/06_route_opt_final.enc`, which is the input to `06_chipfinish.tcl` (stage
numbering is one ahead of the file numbering).

| Stage | Script | Reads | Writes |
|---|---|---|---|
| init | `scripts/01_init.tcl` | LEFs, `mmmc.tcl`, netlist | `dbs/01_init.enc` |
| floorplan + PG | `scripts/02_floorplan_pg.tcl` | `01_init.enc`, `fp.def` | `02_floorplan.enc` (pre-PG), `02_floorplan_pg.enc` |
| place | `scripts/03_place.tcl` | `02_floorplan_pg.enc` | `03_place.enc` |
| CTS | `scripts/04_cts.tcl` | `03_place.enc` | `04_cts.enc`, `04_post_cts_hold.enc` |
| route + opt | `scripts/05_route_opt.tcl` | `04_post_cts_hold.enc` | `05_route_opt.enc`, `06_route_opt_final.enc` |
| chipfinish | `scripts/06_chipfinish.tcl` | `06_route_opt_final.enc` | `07_final.enc`, `outputs/` |

Non-obvious details:

- **Floorplan**: die is `125.84 × 95` with core offsets `{3.64 3.6 3.64 3.6}`.
  Macro placement and pin assignments are read from the hand-authored `fp.def`
  in the repository root (`read_def ./fp.def`; the `write_def` lines are
  commented out, so this file is an input). Inputs are spread on the left and
  outputs on the right edge on M3. Halos are `{3 0 3 5}`, tap cells `TAP01CR9`
  every 50 µm, PG stripes on M6/M5 (width 6, spacing 1.5, pitch 30) plus M4
  straps over the SRAM area.
- **MMMC** (`scripts/mmmc.tcl`): two corners — `ss/1.08 V/125 C/cworst` used for
  setup and `ff/1.32 V/−40 C/cbest` used for hold. One constraint mode `func`
  sources the SDC from NFS. Stage scripts override clock uncertainty
  interactively: 0.45 ns setup at place, 0.30 at CTS, 0.15 at route; 0.05 hold,
  0.04 after route.
- **Place** (`03_place.tcl`): creates path groups (`In2Reg`, `Reg2Out`,
  `In2Out` low weight 5; `Reg2Reg`, `Reg2Mem`, `Mem2Reg`, `Mem2Mem` high weight
  10), runs `place_opt_design`, then adds tie-offs. Top/bottom routing layers
  are M5/M2.
- **CTS** (`04_cts.tcl`): CCOPT with dedicated route types/NDRs (`cts_leaf`
  1w2s M4:M6, `cts_2w2s` for top/trunk M5:M6), generates and sources
  `clock.spec`, then `clock_opt_design` and a post-CTS hold `opt_design`.
- **Route** (`05_route_opt.tcl`): `route_opt_design -setup`, then three
  post-route `opt_design` passes (setup, hold, setup+hold), final `time_design`
  with all analysis views, connectivity/DRC checks.
- **Chipfinish** (`06_chipfinish.tcl`): decap + filler insertion, PG
  re-connection, all final checks/reports, netlist/DEF/MMMC/GDS/SPEF export,
  `07_final.enc`.

## Cell usage

A `dontuse_ref` list (DEL, FILL, ANT, TAP, CLK, large drive strengths such as
`*X20AR9`/`*X05AR9`, TIE, and `*G*` cells) is applied in floorplan and place.
TIE cells are re-enabled and inserted with `add_tieoffs`; decap/filler cells are
inserted only at chipfinish. `dontuse_ref` is duplicated between
`02_floorplan_pg.tcl` and `03_place.tcl` (the place copy also excludes
`*X20AL9`/`*X05AL9`), so keep the two in sync when changing it.

## Repository layout

- `scripts/` — the flow (01–06, `mmmc.tcl`, `eco.tcl`, `fix_drc.tcl`), plus
  `scripts/fix_drc.tcl`, a helper for iterating on `Metal_Short` DRC markers
  (deletes and reroutes the offending nets) and `scripts/eco.tcl`, a template
  for ECO cell swaps followed by `place_detail -eco` and `route_eco`.
- `Makefile` — the six-stage driver.
- `fp.def` — floorplan input (SRAM placement and pin assignments).
- `dbs/`, `logs/`, `rpt/`, `outputs/` — generated artifacts, kept with
  `.gitkeep`; ignored by git.

## Environment and gotchas

- Requires the NFS mounts `/mnt/nfs_share/EE291F` and `/mnt/sharefile/EE291F`
  (the LVT standard-cell LEF is only under `/mnt/sharefile`). Libraries: RVT
  `M31GPSC900HL055PR`, LVT `M31GPSC900HL055PL`, memory `mem55lpw128d16sp`.
  These paths are hard-coded and must be adapted for another environment.
- Innovus runs with 16 CPUs requested, but the license server allows 8;
  `IMPVFG-1198` warnings in the logs are expected.
- `04_cts.tcl` contains `gui_ctd_open` (opens the clock-tree debugger GUI).
  Guard or remove it for headless/batch runs.
- `fp.def` is a floorplan **input** despite the script also having
  commented-out DEF-writing code; editing it changes macro and pin placement.