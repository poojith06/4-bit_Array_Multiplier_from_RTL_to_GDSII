#!/bin/bash
# Opens mult.vcd in GTKWave with report/figures/mult.gtkw on a private Xvfb
# display and saves a screenshot to report/figures/waveform.png.
# Run from the repo root inside the container, after `vvp sim` has written mult.vcd:
#   bash report/gen_waveform_shot.sh
set -e

Xvfb :99 -screen 0 1400x360x24 >/dev/null 2>&1 &
XPID=$!
sleep 2

# Larger fonts so the figure stays readable when printed in the report.
DISPLAY=:99 gtkwave --rcvar 'fontname_signals Monospace 15' \
                    --rcvar 'fontname_waves Monospace 13' \
                    mult.vcd report/figures/mult.gtkw >/dev/null 2>&1 &
GPID=$!
sleep 6

python3 -c "from PIL import ImageGrab; ImageGrab.grab(xdisplay=':99').save('report/figures/waveform.png')"
echo "Saved report/figures/waveform.png"

kill $GPID $XPID
