#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Figure 2: Three-panel horizontal bar chart (Full Academic Year only)
--------------------------------------------------------------------
Panel A: % of speakers (pct_black, pct_hispanic, pct_urm)
Panel B: Speakers per seminar (num_black, num_hispanic, num_urm — regression-adjusted means)
Panel C: % of seminars with any (has_any_black, has_any_hispanic, has_any_urm)

Rows: Black (top), Hispanic, URM
Bars: Control (navy) vs Treatment (red)
Significance annotations and delta labels from OLS + clustered SE.
"""

import os
import warnings

import matplotlib.font_manager as fm
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import statsmodels.api as sm
import statsmodels.formula.api as smf
from matplotlib.ticker import FuncFormatter
from scipy import stats

warnings.filterwarnings("ignore")

fm.findfont("Arial", rebuild_if_missing=True)
plt.rcParams["font.family"] = "sans-serif"
plt.rcParams["font.sans-serif"] = ["Arial", "Helvetica", "DejaVu Sans", "sans-serif"]
plt.rcParams["font.size"] = 14

# Wharton palette
WHARTON_BLUE = "#011F5B"
WHARTON_RED = "#990000"
WHARTON_DARK_GRAY = "#57606C"
WHARTON_LIGHT_GRAY = "#E5E5E5"

# Paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_PATH = os.path.join(SCRIPT_DIR, "../../replication/data/final_data.csv")
OUT_DIR = os.path.join(SCRIPT_DIR, "..")
os.makedirs(OUT_DIR, exist_ok=True)

# Load data
df = pd.read_csv(DATA_PATH)

# Variable engineering
df["has_any_urm"] = (df["num_urm"] > 0).astype(int)
df["has_any_black"] = (df["num_black"] > 0).astype(int)
df["has_any_hispanic"] = (df["num_hispanic"] > 0).astype(int)

# Create discipline dummies (chemistry is omitted reference category)
for disc in ["mathematics", "physics", "computer_science", "mechanical_engineering"]:
    col = disc.replace(" ", "_").lower()
    df[f"disc_{col}"] = (
        df["discipline"].str.lower().str.replace(" ", "_") == col
    ).astype(int)

# Controls
base_controls = [
    "bin_0_1", "bin_1_3", "bin_3_5", "bin_5_7", "bin_7_11", "bin_11_17",
    "disc_mathematics", "disc_physics", "disc_computer_science",
    "disc_mechanical_engineering",
    "batch_1", "batch_2", "batch_3", "batch_4", "batch_5",
    "batch_6", "batch_7", "batch_8", "batch_9",
]
extended_controls = [
    "total_faculty", "frac_urm_faculty", "frac_women_faculty",
    "dept_ranking", "missing_dept_rank",
    "total_urm_peer_faculty", "total_peer_departments", "num_recipients",
]
all_controls = base_controls + extended_controls


def ols_cluster(formula, data):
    lhs, rhs = formula.split("~")
    vars_ = [v.strip() for v in (lhs + rhs).split("+")]
    vars_ = [v for v in vars_ if v in data.columns]
    d = data.dropna(subset=vars_)
    m = smf.ols(formula, data=d).fit()
    cov = sm.stats.sandwich_covariance.cov_cluster(m, d["department_std"])
    se = np.sqrt(np.diag(cov))
    return m, se, d


def stars(p):
    if p < 0.001:
        return "***"
    if p < 0.01:
        return "**"
    if p < 0.05:
        return "*"
    if p < 0.10:
        return "\u2020"
    return ""


# Demographic groups: Black first (largest significant effect), then Hispanic, URM
groups = ["Black", "Hispanic", "Underrepresented Minorities"]

# Panel specifications
panels = {
    "A": {
        "title": "% of Speakers Who Were\u2026",
        "dvs": {"Hispanic": "pct_hispanic", "Black": "pct_black", "Underrepresented Minorities": "pct_urm"},
        "mode": "pct",
        "xlabel": "% of Seminar Speakers",
        "fmt_val": "{:.1f}%",
        "fmt_delta": "\u0394 = +{:.2f}%",
    },
    "B": {
        "title": "# of Speakers Who Were\u2026",
        "dvs": {"Hispanic": "num_hispanic", "Black": "num_black", "Underrepresented Minorities": "num_urm"},
        "mode": "count",
        "xlabel": "Speakers per Seminar",
        "fmt_val": "{:.2f}",
        "fmt_delta": "\u0394 = +{:.2f}",
    },
    "C": {
        "title": "% of Seminars with Any\nSpeakers Who Were\u2026",
        "dvs": {
            "Hispanic": "has_any_hispanic",
            "Black": "has_any_black",
            "Underrepresented Minorities": "has_any_urm",
        },
        "mode": "pct_binary",
        "xlabel": "% of Seminars",
        "fmt_val": "{:.1f}%",
        "fmt_delta": "\u0394 = +{:.2f}%",
    },
}

n_treat = (df["treatment"] == 1).sum()
n_ctrl = (df["treatment"] == 0).sum()


def compute_panel_data(panel_spec):
    results = []
    for grp in groups:
        dv = panel_spec["dvs"][grp]
        mode = panel_spec["mode"]

        c_vals = df.loc[df.treatment == 0, dv]
        t_vals = df.loc[df.treatment == 1, dv]

        # OLS regression for p-value
        formula = f"{dv} ~ treatment + " + " + ".join(all_controls)
        model, se_vec, d = ols_cluster(formula, df)
        t_coef = model.params["treatment"]
        t_se_cl = se_vec[model.params.index.get_loc("treatment")]
        clusters = d["department_std"].nunique()
        p_val = 2 * (1 - stats.t.cdf(abs(t_coef / t_se_cl), clusters - 1))

        # Regression-adjusted means via model.predict() — consistent with figs 2 & 3
        pred_data = pd.DataFrame({"treatment": [0, 1]})
        for ctrl in all_controls:
            if ctrl in df.columns:
                pred_data[ctrl] = df[ctrl].mean()
        preds = model.predict(pred_data)

        if mode == "count":
            c_display = preds.iloc[0]
            t_display = preds.iloc[1]
            c_se = c_vals.sem()
            t_se = t_vals.sem()
            delta = t_coef
        elif mode == "pct_binary":
            c_display = preds.iloc[0] * 100
            t_display = preds.iloc[1] * 100
            c_se = c_vals.sem() * 100
            t_se = t_vals.sem() * 100
            delta = t_coef * 100
        else:  # pct
            c_display = preds.iloc[0]
            t_display = preds.iloc[1]
            c_se = c_vals.sem()
            t_se = t_vals.sem()
            delta = t_coef

        results.append({
            "group": grp,
            "c_val": c_display, "t_val": t_display,
            "c_se": c_se, "t_se": t_se,
            "delta": delta, "p": p_val,
        })
    return results


# ── Layout constants ──
bar_height = 0.25
group_spacing = 1.3
ctrl_offset = 0.40
treat_offset = 0.74
header_band_half = 0.13

# ── Create the figure ──
fig, axes = plt.subplots(1, 3, figsize=(14, 7))
plt.subplots_adjust(wspace=0.40)

for ax_idx, (panel_key, panel_spec) in enumerate(panels.items()):
    ax = axes[ax_idx]
    data = compute_panel_data(panel_spec)

    # ── Pass 1: draw header bands and bars ──
    for grp_idx, row in enumerate(data):
        base = grp_idx * group_spacing
        ctrl_y = base + ctrl_offset
        treat_y = base + treat_offset

        # Gray header band with group name
        ax.axhspan(
            base - header_band_half, base + header_band_half,
            color=WHARTON_LIGHT_GRAY, alpha=0.5, zorder=0, linewidth=0,
        )

        # Control bar
        ax.barh(
            ctrl_y, row["c_val"], bar_height, xerr=row["c_se"],
            color=WHARTON_BLUE, edgecolor="darkblue", linewidth=1.5,
            capsize=4, error_kw={"linewidth": 1.5, "ecolor": "black"}, zorder=2,
        )
        # Treatment bar
        ax.barh(
            treat_y, row["t_val"], bar_height, xerr=row["t_se"],
            color=WHARTON_RED, edgecolor="darkred", linewidth=1.5,
            capsize=4, error_kw={"linewidth": 1.5, "ecolor": "black"}, zorder=2,
        )

    # Extend x-axis for annotation room
    xlim_auto = ax.get_xlim()
    x_extent = xlim_auto[1]
    ax.set_xlim(xlim_auto[0], x_extent * 1.35)

    # ── Pass 2: text labels and annotations ──
    for grp_idx, row in enumerate(data):
        base = grp_idx * group_spacing
        ctrl_y = base + ctrl_offset
        treat_y = base + treat_offset
        c_val, t_val = row["c_val"], row["t_val"]

        # Group name centered in header band (x=0.38 to center over bar area)
        ax.text(
            0.38, base, row["group"],
            transform=ax.get_yaxis_transform(),
            ha="center", va="center",
            fontsize=10, fontweight="bold", color=WHARTON_DARK_GRAY, zorder=1,
        )

        # Value labels inside bars
        ax.text(
            c_val / 2, ctrl_y,
            panel_spec["fmt_val"].format(c_val),
            ha="center", va="center", fontsize=10, fontweight="bold",
            color="white", zorder=3,
        )
        ax.text(
            t_val / 2, treat_y,
            panel_spec["fmt_val"].format(t_val),
            ha="center", va="center", fontsize=10, fontweight="bold",
            color="white", zorder=3,
        )

        # Significance annotation
        if row["p"] < 0.10:
            xmax = max(c_val + row["c_se"], t_val + row["t_se"])
            mid_y = base + (ctrl_offset + treat_offset) / 2
            sig = stars(row["p"])
            delta_label = panel_spec["fmt_delta"].format(abs(row["delta"]))
            ax.text(
                xmax + x_extent * 0.03, mid_y,
                f"{delta_label} {sig}",
                ha="left", va="center", fontsize=11, fontweight="bold",
                color="black", zorder=5,
            )

    # ── Y-axis: "Control" / "Treatment" tick labels ──
    yticks = []
    yticklabels = []
    for grp_idx in range(len(groups)):
        base = grp_idx * group_spacing
        yticks.extend([base + ctrl_offset, base + treat_offset])
        yticklabels.extend(["Control", "Treatment"])
    ax.set_yticks(yticks)
    ax.set_yticklabels(yticklabels, fontsize=10)
    ax.tick_params(axis="y", length=0, pad=4)

    # X-axis formatting
    if panel_spec["mode"] in ("pct", "pct_binary"):
        ax.xaxis.set_major_formatter(FuncFormatter(lambda x, p: f"{x:.0f}%"))

    # Y-axis limits (tight)
    y_top = -header_band_half - 0.06
    y_bottom = (
        (len(groups) - 1) * group_spacing + treat_offset + bar_height / 2 + 0.06
    )
    ax.set_ylim(y_top, y_bottom)

    # Panel title and x-axis label
    ax.set_title(
        f"{panel_key}.  {panel_spec['title']}",
        fontsize=14, fontweight="bold", pad=12, loc="left",
    )
    ax.set_xlabel(panel_spec["xlabel"], fontsize=12, fontweight="bold")

    # Spines
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.spines["left"].set_color(WHARTON_DARK_GRAY)
    ax.spines["bottom"].set_color(WHARTON_DARK_GRAY)
    ax.spines["left"].set_linewidth(1.4)
    ax.spines["bottom"].set_linewidth(1.4)

    ax.invert_yaxis()

plt.tight_layout()

out_path = os.path.join(OUT_DIR, "figure_2.png")
plt.savefig(out_path, dpi=600, bbox_inches="tight", facecolor="white")
plt.close()
print(f"Figure 2 saved to: {out_path}")
