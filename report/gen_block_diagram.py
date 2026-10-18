#!/usr/bin/env python3
"""
Draws the mult_array block diagram: input registers, 16 AND gates, the 3 rows
of 4 full adders (labelled with their RTL instance names) and the output
register. Columns are aligned by bit weight (LSB on the right), so every
connection from the table in Section 2 of RTL_to_GDS.pdf is drawn exactly:
sums drop straight down, carries ripple right-to-left, and each row's final
carry goes diagonally into the next row.

Run from the repo root: python3 report/gen_block_diagram.py
Output: report/figures/block_diagram.png
"""
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch, Rectangle

OUT = Path(__file__).resolve().parent / "figures" / "block_diagram.png"

PITCH = 1.5                    # column pitch (one column per bit weight)
FA_W, FA_H = 1.05, 0.62
AND_W, AND_H = 0.88, 0.48
ROW_Y = {1: 6.7, 2: 4.6, 3: 2.5}   # bottom y of each full-adder row
AND0_Y = 8.75                  # row 0 AND gates
REG_Y = 0.55                   # output register
FS = 10

C_REG, C_AND, C_FA = "#cfe2f3", "#fff2cc", "#f4cccc"


def X(w):
    """Left x of the column for bit weight w (weight 7 on the left)."""
    return 0.6 + (7 - w) * PITCH


def box(ax, x, y, w, h, text, fc, fs=FS):
    ax.add_patch(Rectangle((x, y), w, h, fc=fc, ec="black", lw=1.1, zorder=3))
    ax.text(x + w / 2, y + h / 2, text, ha="center", va="center", fontsize=fs, zorder=4)


def arrow(ax, p, q, color="black", lw=1.2):
    ax.add_patch(FancyArrowPatch(p, q, arrowstyle="-|>", mutation_scale=11,
                                 color=color, lw=lw, zorder=2,
                                 shrinkA=0, shrinkB=0))


def main():
    fig, ax = plt.subplots(figsize=(12, 9.6))
    ax.set_xlim(0, 13.6)
    ax.set_ylim(-0.6, 11.4)
    ax.axis("off")

    # Input registers and the operand bus feeding all 16 AND gates
    box(ax, X(6), 10.4, 2.4, 0.65, "a_reg[3:0]  (4 FF)", C_REG)
    box(ax, X(3), 10.4, 2.4, 0.65, "b_reg[3:0]  (4 FF)", C_REG)
    ax.text(X(6) + 1.2, 11.2, "a[3:0]", ha="center", fontsize=FS + 1)
    ax.text(X(3) + 1.2, 11.2, "b[3:0]", ha="center", fontsize=FS + 1)
    arrow(ax, (X(6) + 1.2, 11.12), (X(6) + 1.2, 11.05))
    arrow(ax, (X(3) + 1.2, 11.12), (X(3) + 1.2, 11.05))
    ax.plot([X(7), X(0) + FA_W], [9.85, 9.85], color="gray", lw=3, zorder=1)
    ax.plot([X(6) + 1.2, X(6) + 1.2], [10.4, 9.85], color="gray", lw=3, zorder=1)
    ax.plot([X(3) + 1.2, X(3) + 1.2], [10.4, 9.85], color="gray", lw=3, zorder=1)
    ax.text(X(7), 9.45, "operand bus: AND gate pp$_i$[j] = a_reg[j] & b_reg[i]   (16 AND gates)",
            fontsize=FS, color="dimgray")

    # Row 0: four AND gates, no adders
    for j in range(4):
        box(ax, X(j), AND0_Y, AND_W, AND_H, f"AND\npp0[{j}]", C_AND, FS - 1)
    ax.text(12.65, AND0_Y + 0.2, "Row 0", fontsize=FS + 1, fontweight="bold")

    # Rows 1-3: each full adder fa_r{k}_{j} sits in column of weight k + j
    for k in (1, 2, 3):
        y = ROW_Y[k]
        ax.text(12.65, y + 0.25, f"Row {k}", fontsize=FS + 1, fontweight="bold")
        for j in range(4):
            x = X(k + j)
            box(ax, x, y, FA_W, FA_H, f"FA\nfa_r{k}_{j}", C_FA, FS - 1)
            # partial-product AND gate feeding input a of this adder
            ax_ = x + 0.5
            box(ax, ax_, y + 0.95, AND_W, AND_H, f"AND\npp{k}[{j}]", C_AND, FS - 1)
            arrow(ax, (ax_ + AND_W / 2, y + 0.95), (ax_ + AND_W / 2, y + FA_H))
            # input b of this adder: r_{k-1}[j]
            top = (x + 0.25, y + FA_H)
            if k == 1 and j < 3:          # r0[j] = pp0[j+1]
                arrow(ax, (X(j + 1) + 0.25, AND0_Y), top)
            elif k == 1 and j == 3:       # r0[3] = 0
                ax.text(x + 0.25, y + FA_H + 0.45, "0", ha="center", fontsize=FS)
                arrow(ax, (x + 0.25, y + FA_H + 0.4), top)
            elif j < 3:                   # r_{k-1}[j] = s_{k-1}[j+1]
                arrow(ax, (x + 0.25, ROW_Y[k - 1]), top)
            else:                         # r_{k-1}[3] = c_{k-1}[4]
                yc = ROW_Y[k - 1] + 0.3
                ax.plot([X(k + 2), x + 0.25], [yc, yc], color="red", lw=1.2, zorder=2)
                arrow(ax, (x + 0.25, yc), top, color="red")
            # carry chain: c_k[j+1] from fa_r{k}_{j} into fa_r{k}_{j+1}
            if j < 3:
                arrow(ax, (x, y + 0.3), (X(k + j + 1) + FA_W, y + 0.3), color="red")
        # carry-in of the first adder in each row is 0
        ax.text(X(k) + FA_W + 0.32, y + 0.3, "0", va="center", fontsize=FS)
        arrow(ax, (X(k) + FA_W + 0.27, y + 0.3), (X(k) + FA_W, y + 0.3), color="red")

    # Product bits into the output register
    REG_TOP = REG_Y + 0.65
    arrow(ax, (X(0) + 0.25, AND0_Y), (X(0) + 0.25, REG_TOP))              # p[0] = pp0[0]
    for k in (1, 2):
        arrow(ax, (X(k) + 0.25, ROW_Y[k]), (X(k) + 0.25, REG_TOP))         # p[k] = s_k[0]
    for j in range(4):
        arrow(ax, (X(3 + j) + 0.25, ROW_Y[3]), (X(3 + j) + 0.25, REG_TOP)) # p[3+j] = s3[j]
    ax.plot([X(6), X(7) + 0.25], [ROW_Y[3] + 0.3, ROW_Y[3] + 0.3], color="red", lw=1.2)
    arrow(ax, (X(7) + 0.25, ROW_Y[3] + 0.3), (X(7) + 0.25, REG_TOP), color="red")  # p[7] = c3[4]

    box(ax, X(7), REG_Y, X(0) + FA_W - X(7), 0.65, "p_reg[7:0]   (8 FF)", C_REG, FS + 1)
    for w in range(8):
        ax.text(X(w) + 0.32, REG_TOP + 0.08, f"p[{w}]", fontsize=FS - 1, color="darkblue")
    arrow(ax, ((X(7) + X(0) + FA_W) / 2, REG_Y), ((X(7) + X(0) + FA_W) / 2, REG_Y - 0.5))
    ax.text((X(7) + X(0) + FA_W) / 2 + 0.15, REG_Y - 0.45, "p[7:0]", fontsize=FS + 1)

    # Legend
    ax.text(X(7), -0.45, "black: sum / partial-product bits     red: carries     "
            "columns aligned by bit weight (p[7] left, p[0] right)",
            fontsize=FS - 1, color="dimgray")

    OUT.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(OUT, dpi=200, bbox_inches="tight")
    print(f"Saved {OUT}")


if __name__ == "__main__":
    main()
