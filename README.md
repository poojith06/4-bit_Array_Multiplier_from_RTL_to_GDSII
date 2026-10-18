# 4-bit Array Multiplier — RTL to GDSII

Digital VLSI Design assignment: a 4-bit unsigned array multiplier taken
from RTL to GDSII on SkyWater SKY130 using open-source tools.

## Team

| Member       | Roll number  |
|--------------|--------------|
| Sai Poojith  | 2025122010   |
| Aneesh       | 2025122002   |

## Environment

All tools run inside the IIC-OSIC-TOOLS Docker image (VNC mode). The
IIC-OSIC-TOOLS repo is cloned outside this repo, in `~/tools/iic-osic-tools`.
`~/eda/designs` on the host is mounted as `/foss/designs` in the container.

Tool versions in the container: Icarus Verilog 14.0 (devel), Yosys 0.70,
OpenSTA 3.1.0, LibreLane v3.1.0.dev3, GTKWave 3.3, KLayout.

Container commands are run from the repo root
(`/foss/designs/4-bit_Array_Multiplier_from_RTL_to_GDSII`) with:

```
docker exec iic-osic-tools_xvnc_uid_1000 bash -lc "cd /foss/designs/4-bit_Array_Multiplier_from_RTL_to_GDSII && <command>"
```

## Commands run, in order

### Setup

On the host:
```
git clone --depth=1 https://github.com/iic-jku/iic-osic-tools.git ~/tools/iic-osic-tools
cd ~/tools/iic-osic-tools && DESIGNS="$HOME/eda/designs" ./start_vnc.sh
docker ps                      # container name: iic-osic-tools_xvnc_uid_1000
```

The image defaults to the `ihp-sg13g2` PDK. `sak-pdk` is an alias that only
exists in interactive shells, so the PDK is selected for every shell with
`~/eda/designs/.designinit` (outside this repo; the container sources it at
startup). It contains the same command that `sak-pdk sky130A` runs:
```
source sak-pdk-script.sh sky130A > /dev/null
```

Checks (Section 4.2), inside the container:
```
iverilog -V | head -1
yosys -V
sta -version
echo $PDK_ROOT $PDK            # -> /foss/pdks sky130A
```

### Part A — RTL design and verification
```
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim                        # PASS: 256 vectors checked, 0 errors
```
Error test (task 6): changed `assign sum = a ^ b ^ cin;` to `assign sum = a ^ b;`
in `rtl/full_adder.v`, then:
```
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim                        # FAIL: 256 vectors checked, 95 errors
```
Reverted the change, then:
```
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim                        # PASS: 256 vectors checked, 0 errors
```
Waveform and block diagram:
```
gtkwave mult.vcd report/figures/mult.gtkw      # interactive view of the 5 x 7 example
bash report/gen_waveform_shot.sh               # saves report/figures/waveform.png
python3 report/gen_block_diagram.py            # saves report/figures/block_diagram.png
```

### Part B — Logic synthesis
```
yosys -c synth/synth.tcl
CELLS=$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/verilog
iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY=#1 -o gls \
  tb/tb_mult.v $CELLS/primitives.v $CELLS/sky130_fd_sc_hd.v synth/mult_array_netlist.v
vvp gls                        # PASS: 256 vectors checked, 0 errors
```
Note: the first gate-level run printed `FAIL: 256 vectors checked, 239 errors`,
with every result one vector late. The cause was the testbench: it sampled `p`
1 ns after the clock edge, at the same time as the 1 ns clk-to-q delay of the
SKY130 flip-flop models. `tb/tb_mult.v` was changed to compare at the falling
edge after the second rising edge. All Part A runs above were then repeated
with the fixed testbench and gave the results shown.

### Part C — Static timing analysis
```
sta sta/sta.tcl                # with "set T 10":   worst slack max 7.40 (7.404 in report)
```
Tmin = 10 - 7.404 = 2.596 ns -> 2.60 ns. Edited `sta/sta.tcl` to `set T 2.60`, then:
```
sta sta/sta.tcl                # with "set T 2.60": worst slack max 0.00 (0.004 in report)
```
The final `sta/mult_array_timing.rpt` is from the T = 2.60 ns run.

### Part D — Place and route
CLOCK_PERIOD = 1.2 x 2.596 = 3.115 ns -> rounded up to the next 0.5 ns = 3.5 ns.
```
cd pnr
librelane config.json
```
Each time the run failed on setup timing, `CLOCK_PERIOD` in `pnr/config.json`
was increased by 0.5 ns and the same command was run again. LibreLane's
default timing corners were kept (no corners removed or disabled).

#### LibreLane run log

Values are from each run's `final/metrics.json`. "Worst setup slack" is the
worst over all 9 corners (what LibreLane signs off on); the tt column is the
nominal typical corner `nom_tt_025C_1v80`. DRC is Magic/KLayout.

| # | CLOCK_PERIOD (ns) | Run folder (`pnr/runs/`) | Result | Worst setup slack (ns) | Worst corner | Setup violations | Corners with violations | tt slack (ns) | DRC | LVS |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 3.5 | RUN_2026-10-18_20-47-57 | FAIL (setup) | -2.154 | max_ss_100C_1v60 | 15 | max/min/nom_ss_100C_1v60 | 0.587 | 0/0 | 0 |
| 2 | 4.0 | RUN_2026-10-18_20-50-52 | FAIL (setup) | -1.654 | max_ss_100C_1v60 | 12 | max/min/nom_ss_100C_1v60 | 1.087 | 0/0 | 0 |
| 3 | 4.5 | RUN_2026-10-18_20-53-39 | FAIL (setup) | -1.154 | max_ss_100C_1v60 | 12 | max/min/nom_ss_100C_1v60 | 1.587 | 0/0 | 0 |
| 4 | 5.0 | RUN_2026-10-18_20-56-35 | FAIL (setup) | -0.654 | max_ss_100C_1v60 | 9 | max/min/nom_ss_100C_1v60 | 2.087 | 0/0 | 0 |
| 5 | 5.5 | RUN_2026-10-18_20-59-51 | FAIL (setup) | -0.155 | max_ss_100C_1v60 | 3 | max/min/nom_ss_100C_1v60 | 2.587 | 0/0 | 0 |
| 6 | 6.0 | RUN_2026-10-18_21-02-44 | FAIL (setup) | -0.107 | max_ss_100C_1v60 | 3 | max/min/nom_ss_100C_1v60 | 2.899 | 0/0 | 0 |
| 7 | 6.5 | RUN_2026-10-18_21-05-19 | FAIL (setup) | -0.136 | max_ss_100C_1v60 | 3 | max/min/nom_ss_100C_1v60 | 3.199 | 0/0 | 0 |
| 8 | 7.0 | RUN_2026-10-18_21-07-54 | **PASS** | +0.364 | max_ss_100C_1v60 | 0 | - | 3.699 | 0/0 | 0 |

Number of runs needed: 8. Runs 6 and 7 improved by much less than 0.5 ns.
Synthesis (67 cells, 738.208 um^2) and the layout up to CTS (1224.92 um^2)
were identical in every run. Only the post-CTS timing-repair step
(`37-openroad-resizertimingpostcts`) differed. It upsized gates by
101.35 um^2 (to 1326.27 um^2) up to 5.5 ns and by 73.83 um^2 at 6.0 ns, and
did nothing at 6.5 and 7.0 ns, where its pre-route estimate showed no
violation. With less upsizing the slow-corner path was slower, so run 8
(7.0 ns, same netlist as run 7) was the first to pass.

Copied the final run's outputs:
```
cp pnr/runs/RUN_2026-10-18_21-07-54/final/metrics.json pnr/metrics.json
cp pnr/runs/RUN_2026-10-18_21-07-54/final/gds/mult_array.gds pnr/mult_array.gds
```
Layout screenshots (KLayout batch mode):
```
klayout -zz -r report/gen_layout_shots.py
```

## Report

`report/report.pdf` is built from `report/report.tex` (IEEEtran, two-column)
with pdflatex on the host (TeX Live installed with
`sudo apt install -y texlive-latex-extra texlive-publishers`). Run twice so
references resolve; build files go to a separate folder, then the PDF is
copied back:
```
cd report
mkdir -p /tmp/latex-build
pdflatex -interaction=nonstopmode -output-directory=/tmp/latex-build report.tex
pdflatex -interaction=nonstopmode -output-directory=/tmp/latex-build report.tex
cp /tmp/latex-build/report.pdf report.pdf
```

Figure helpers kept in `report/`:
- `report/figures/mult.gtkw` — GTKWave save file for the 5 x 7 example
  (signals, decimal radix, zoom, named markers)
- `report/gen_waveform_shot.sh` — opens that save file on a virtual display
  and saves `report/figures/waveform.png`
- `report/gen_block_diagram.py` — saves `report/figures/block_diagram.png`
- `report/gen_layout_shots.py` — KLayout batch script for the two layout images
