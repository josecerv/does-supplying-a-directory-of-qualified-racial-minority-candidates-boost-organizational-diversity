#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Figure 3: Black Speaker Sources & Treatment Effect Decomposition
Four-panel (2x2) — shaded trapezoid connectors link A->C / B->D.
Four distinct colors (shifted red/blue variants) so each concept has
its own hue, avoiding confusion with Figure 2's treatment/control palette.

Output: figures/figure_3.png
"""

import os
import warnings

import matplotlib.colors as mcolors
import matplotlib.font_manager as fm
import matplotlib.gridspec as gridspec
import matplotlib.pyplot as plt
import matplotlib.transforms as mtransforms
import pandas as pd
from matplotlib.lines import Line2D
from matplotlib.patches import Polygon
from matplotlib.ticker import FuncFormatter

warnings.filterwarnings("ignore")

fm.findfont("Arial", rebuild_if_missing=True)
plt.rcParams["font.family"] = "sans-serif"
plt.rcParams["font.sans-serif"] = ["Arial", "Helvetica", "DejaVu Sans", "sans-serif"]
plt.rcParams["font.size"] = 16

DARK_GRAY  = "#57606C"
LIGHT_GRAY = "#E5E5E5"

# ── Four-color palette ───────────────────────────────────────────────
# Left column (A/C — Directory): wine red + steel blue
# Right column (B/D — Peer):    golden yellow + forest green
#
DB_FOCAL  = "#832040"   # wine red — From URM Directory
DB_COMP   = "#2E5984"   # steel blue — Not From URM Directory
PEER_FOCAL = "#9A7D0A"  # dark gold — From Peer Departments
PEER_COMP  = "#1A7A6D"  # teal — From Outside Peer Departments

def _text_color(bg_hex):
    """Return 'white' or 'black' for best readability on bg_hex."""
    r, g, b = int(bg_hex[1:3], 16), int(bg_hex[3:5], 16), int(bg_hex[5:7], 16)
    lum = 0.299 * r + 0.587 * g + 0.114 * b
    return "black" if lum > 140 else "white"

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_PATH  = os.path.join(SCRIPT_DIR, "../../replication/data/final_data.csv")
OUT_DIR    = os.path.join(SCRIPT_DIR, "..")
os.makedirs(OUT_DIR, exist_ok=True)


# ══════════════════════════════════════════════════════════════════════
# Data
# ══════════════════════════════════════════════════════════════════════
df    = pd.read_csv(DATA_PATH)
share = lambda a, b: a / (a + b) * 100

# Panels A/B: control-group composition (baseline rates)
ctrl   = df[df["treatment"] == 0]
s_ctrl = lambda col: ctrl[col].sum()
base_db   = share(s_ctrl("num_black_from_db"),  s_ctrl("num_black_not_from_db"))
base_peer = share(s_ctrl("num_black_inpeer"),   s_ctrl("num_black_outside"))

# Panels C/D: treatment-effect decomposition (regression coefficients)
eff_db   = share(0.098, 0.631)
eff_peer = share(0.544, 0.185)

# Expansion factors
expand_db   = eff_db / base_db
expand_peer = eff_peer / base_peer


# ══════════════════════════════════════════════════════════════════════
# Figure
# ══════════════════════════════════════════════════════════════════════
fig = plt.figure(figsize=(14, 7.5))

# Layout: header_top | gap_top | row_top | gap_above | header_bot | gap_below | row_bot
gs = gridspec.GridSpec(
    7, 2,
    height_ratios=[0.10, 0.08, 1.0, 0.08, 0.10, 0.08, 1.0],
    hspace=0.02,
    wspace=0.16,
    left=0.06, right=0.98,
    top=0.96, bottom=0.05,
)

BH = 0.72   # uniform bar height for all panels


# ── Section headers ──────────────────────────────────────────────────
# Deferred: gray bands are drawn after panels exist so we can read
# their exact left/right positions (flush with bar edges).
_header_bands = []

def make_header(row, text, gray_bg=False):
    ax = fig.add_subplot(gs[row, :])
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.set_xticks([])
    ax.set_yticks([])
    for sp in ax.spines.values():
        sp.set_visible(False)
    ax.patch.set_visible(False)
    if gray_bg:
        _header_bands.append(ax)
        ax.set_zorder(6)
    ax.text(0.5, 0.45, text,
            ha="center", va="center",
            fontsize=15, fontweight="bold", color="black",
            transform=ax.transAxes, clip_on=False, zorder=7)

make_header(0,
    "Where Did Black Speakers in the 2024\u201325 STEM Seminar Series "
    "Come From?",
    gray_bg=True)
# Invisible gap rows (after top header, above/below bottom header)
for gap_row in (1, 3, 5):
    ax_gap = fig.add_subplot(gs[gap_row, :])
    ax_gap.axis("off")

make_header(4,
    "What Proportion of the Treatment Effect on the % of Black Speakers "
    "in a STEM Seminar Series Came From Different Sources?",
    gray_bg=True)


# ── Panel letter in left margin ──────────────────────────────────────
def add_panel_letter(ax, letter):
    trans = mtransforms.blended_transform_factory(ax.transAxes, ax.transData)
    ax.text(-0.03, BH / 2, letter,
            ha="right", va="top",
            fontsize=23, fontweight="bold", color="black",
            transform=trans, clip_on=False)


# ── Draw top panels (A/B) — percentages only, no descriptive labels ─
def draw_top_panel(ax, letter, focal_pct, fc, fc_edge, cc, cc_edge,
                   small_focal=False):
    other_pct = 100 - focal_pct

    ax.set_xlim(0, 100)
    ax.set_ylim(-BH / 2, BH / 2)          # no padding — bar fills axes
    ax.set_yticks([])
    ax.set_xticks([])
    for sp in ax.spines.values():
        sp.set_visible(False)
    ax.patch.set_visible(False)

    # Bars
    ax.barh(0, focal_pct, BH, left=0,
            color=fc, edgecolor="none", linewidth=0, zorder=2)
    ax.barh(0, other_pct, BH, left=focal_pct,
            color=cc, edgecolor="none", linewidth=0, zorder=2)

    # Percentage labels — adaptive text color for readability
    fc_tc = _text_color(fc)
    cc_tc = _text_color(cc)
    if small_focal:
        ax.text(focal_pct / 2, 0, f"{focal_pct:.1f}%",
                ha="center", va="center",
                fontsize=15, fontweight="bold", color=fc_tc,
                rotation=90, zorder=3)
    else:
        ax.text(focal_pct / 2, 0, f"{focal_pct:.1f}%",
                ha="center", va="center",
                fontsize=27, fontweight="bold", color=fc_tc, zorder=3)

    bcx = focal_pct + other_pct / 2
    ax.text(bcx, 0, f"{other_pct:.1f}%",
            ha="center", va="center",
            fontsize=27, fontweight="bold", color=cc_tc, zorder=3)

    add_panel_letter(ax, letter)
    return ax


# ── Draw bottom panels (C/D) ────────────────────────────────────────
def draw_bot_panel(ax, letter, focal_pct, focal_lbl, other_lbl,
                   fc, fc_edge, cc, cc_edge):
    other_pct = 100 - focal_pct
    lbl_y = -(BH / 2 + 0.06)

    ax.set_xlim(0, 100)
    ax.set_ylim(-(BH / 2 + 0.18), BH / 2)   # no top padding — bar top = axes top
    ax.set_yticks([])
    ax.set_xticks([0, 25, 50, 75, 100])
    ax.xaxis.set_major_formatter(FuncFormatter(lambda x, _: f"{x:.0f}%"))
    ax.tick_params(axis="x", labelsize=16)
    for sp in ["top", "right", "left"]:
        ax.spines[sp].set_visible(False)
    ax.spines["bottom"].set_color(DARK_GRAY)
    ax.spines["bottom"].set_linewidth(1.4)
    ax.patch.set_visible(False)

    # Bars
    ax.barh(0, focal_pct, BH, left=0,
            color=fc, edgecolor="none", linewidth=0, zorder=2)
    ax.barh(0, other_pct, BH, left=focal_pct,
            color=cc, edgecolor="none", linewidth=0, zorder=2)

    # Percentages inside — adaptive text color
    fc_tc = _text_color(fc)
    cc_tc = _text_color(cc)
    focal_fs = 21 if focal_pct < 20 else 25
    other_fs = 21 if other_pct < 20 else 25
    ax.text(focal_pct / 2, 0, f"{focal_pct:.1f}%",
            ha="center", va="center",
            fontsize=focal_fs, fontweight="bold", color=fc_tc, zorder=3)
    ax.text(focal_pct + other_pct / 2, 0, f"{other_pct:.1f}%",
            ha="center", va="center",
            fontsize=other_fs, fontweight="bold", color=cc_tc, zorder=3)

    # Labels below
    ax.text(0, lbl_y, focal_lbl,
            ha="left", va="top",
            fontsize=15, fontweight="bold", color=fc,
            linespacing=1.2, zorder=3, clip_on=False)
    ax.text(100, lbl_y, other_lbl,
            ha="right", va="top",
            fontsize=15, fontweight="bold", color=cc,
            linespacing=1.2, zorder=3, clip_on=False)

    add_panel_letter(ax, letter)
    return ax


# ── Draw all panels ─────────────────────────────────────────────────
ax_a = fig.add_subplot(gs[2, 0])
draw_top_panel(ax_a, "A.", base_db,
               DB_FOCAL, DB_FOCAL, DB_COMP, DB_COMP, small_focal=True)

ax_b = fig.add_subplot(gs[2, 1])
draw_top_panel(ax_b, "B.", base_peer,
               PEER_FOCAL, PEER_FOCAL, PEER_COMP, PEER_COMP)

ax_c = fig.add_subplot(gs[6, 0])
draw_bot_panel(ax_c, "C.", eff_db,
               "From URM Directory", "Not From URM Directory",
               DB_FOCAL, DB_FOCAL, DB_COMP, DB_COMP)

ax_d = fig.add_subplot(gs[6, 1])
draw_bot_panel(ax_d, "D.", eff_peer,
               "From Peer Departments", "From Outside Peer Departments",
               PEER_FOCAL, PEER_FOCAL, PEER_COMP, PEER_COMP)


# ── Helper: data coords → figure coords (one consistent method) ──────
fig.canvas.draw()

def to_fig(ax, x_data, y_data):
    """Convert (x, y) in an axes' data space to figure-fraction coords."""
    return fig.transFigure.inverted().transform(
        ax.transData.transform((x_data, y_data)))


# ── Deferred gray header bands — flush with bar x-edges ──────────────
bar_x0 = to_fig(ax_a, 0, 0)[0]
bar_x1 = to_fig(ax_b, 100, 0)[0]

for hdr_ax in _header_bands:
    pos = hdr_ax.get_position()
    fig.patches.append(plt.Rectangle(
        (bar_x0, pos.y0), bar_x1 - bar_x0, pos.height,
        transform=fig.transFigure, facecolor=LIGHT_GRAY,
        edgecolor="none", zorder=5.5, clip_on=False,
    ))


# ── Shaded trapezoid connectors: A→C / B→D ──────────────────────────
# Trapezoid spans from top-axes bottom to bottom-axes top (the full
# gap), so the shading meets the bars flush — no visible overhang.
for ax_top, ax_bot, pct_top, pct_bot, fc, fc_edge, vert_on_top in [
    (ax_a, ax_c, base_db, eff_db, DB_FOCAL, DB_FOCAL, True),
    (ax_b, ax_d, base_peer, eff_peer, PEER_FOCAL, PEER_FOCAL, False),
]:
    pos_t = ax_top.get_position()
    pos_b = ax_bot.get_position()
    x0_top = to_fig(ax_top, 0, 0)[0]
    x0_bot = to_fig(ax_bot, 0, 0)[0]

    # x-right: proportional within the axes width
    xr_top = to_fig(ax_top, pct_top, 0)[0]
    xr_bot = to_fig(ax_bot, pct_bot, 0)[0]

    # y: axes boundaries (flush with bars)
    y_top = pos_t.y0                       # bottom of top axes
    y_bot = pos_b.y0 + pos_b.height       # top of bottom axes

    top_left  = (x0_top, y_top)
    top_right = (xr_top, y_top)
    bot_right = (xr_bot, y_bot)
    bot_left  = (x0_bot, y_bot)

    # Filled trapezoid — below gray header band
    rgb = mcolors.to_rgb(fc)
    trap = Polygon(
        [top_left, top_right, bot_right, bot_left],
        closed=True,
        facecolor=(*rgb, 0.25),
        edgecolor="none",
        transform=fig.transFigure,
        clip_on=False, zorder=4.5,
    )
    fig.add_artist(trap)

    # Border lines — offset vertical left side inward by half linewidth
    # so its outer edge is flush with the bar edge (no bump)
    lw = 2.0
    half_lw_fig = (lw / 72.0) / fig.get_size_inches()[0] / 2.0

    # Left vertical line — A→C: above header; B→D: below header
    vert_z = 6.5 if vert_on_top else 4.5
    fig.add_artist(Line2D(
        [x0_top + half_lw_fig, x0_bot + half_lw_fig], [y_top, y_bot],
        color=fc_edge, linewidth=lw,
        transform=fig.transFigure, clip_on=False,
        zorder=vert_z,
    ))
    # Right diagonal line
    fig.add_artist(Line2D(
        [xr_top, xr_bot], [y_top, y_bot],
        color=fc_edge, linewidth=lw,
        transform=fig.transFigure, clip_on=False,
        zorder=4.5,
    ))


# ── Save ─────────────────────────────────────────────────────────────
out_path = os.path.join(OUT_DIR, "figure_3.png")
fig.savefig(out_path, dpi=600, facecolor="white")
plt.close(fig)
print(f"\nFigure saved: {out_path}")
