# KLayout batch script: saves two screenshots of the final layout.
# Run from the repo root inside the container:
#   klayout -zz -r report/gen_layout_shots.py
# Optional: -rd gds=<file> to use a different GDS (default pnr/mult_array.gds).
#
# Outputs:
#   report/figures/layout_full.png  whole die
#   report/figures/layout_zoom.png  zoomed region showing cell rows and metal wires
import os
import pya

gds_path = globals().get("gds", "pnr/mult_array.gds")
out_dir = globals().get("outdir", "report/figures")
lyp = os.path.join(os.environ["PDK_ROOT"], "sky130A", "libs.tech", "klayout", "tech", "sky130A.lyp")

view = pya.LayoutView()
view.load_layout(gds_path, True)
view.load_layer_props(lyp)
view.max_hier()
view.set_config("background-color", "#ffffff")
view.set_config("grid-visible", "false")
view.set_config("text-visible", "false")

# Whole die
view.zoom_fit()
view.save_image(os.path.join(out_dir, "layout_full.png"), 1600, 1600)

# Zoomed view: a 36 x 24 um window at the centre of the die, where the
# standard cells are placed, so individual cell rows and wires are visible.
bbox = view.cellview(0).cell.dbbox()
cx, cy = bbox.center().x, bbox.center().y
view.zoom_box(pya.DBox(cx - 18, cy - 12, cx + 18, cy + 12))
view.save_image(os.path.join(out_dir, "layout_zoom.png"), 1800, 1200)

print("Saved layout_full.png and layout_zoom.png to", out_dir)
