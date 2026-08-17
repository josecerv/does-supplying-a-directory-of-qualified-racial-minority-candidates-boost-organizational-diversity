#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Figure S4: Heterogeneity by Discipline — Black Speaker Outcomes
----------------------------------------------------------------
Three-panel horizontal bar chart matching Figure 1 style.

Panel A: % of speakers who were Black (by discipline)
Panel B: Total # of speakers who were Black (by discipline)
Panel C: % of seminars with any Black speakers (by discipline)

Rows: Disciplines (grey header bands), sorted by baseline control rate
Bars: Control (navy) vs Treatment (red)
Significance annotations from OLS + clustered SE within each discipline.
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
plt.rcParams["font.size"] = 24

# Wharton palette
WHARTON_BLUE = "#011F5B"
WHARTON_RED = "#990000"
WHARTON_DARK_GRAY = "#57606C"
WHARTON_LIGHT_GRAY = "#E5E5E5"

# Paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_PATH = os.path.join(SCRIPT_DIR, "../../replication/data/final_data.csv")
OUT_DIR = os.path.join(SCRIPT_DIR, "../supplemental")
os.makedirs(OUT_DIR, exist_ok=True)

# Load data
df = pd.read_csv(DATA_PATH)

# Variable engineering
df["has_any_black"] = (df["num_black"] > 0).astype(int)

# Controls (no discipline dummies — we subset by discipline)
seniority_controls = [
    "bin_0_1", "bin_1_3", "bin_3_5", "bin_5_7", "bin_7_11", "bin_11_17",
]
batch_controls = [
    "batch_1", "batch_2", "batch_3", "batch_4", "batch_5",
    "batch_6", "batch_7", "batch_8", "batch_9",
]
extended_controls = [
    "total_faculty", "frac_urm_faculty", "frac_women_faculty",
    "dept_ranking", "missing_dept_rank",
    "total_urm_peer_faculty", "total_peer_departments", "num_recipients",
]
all_controls = seniority_controls + batch_controls + extended_controls

# Disciplines — sort by baseline control pct_black (ascending)
DISCIPLINES = [
    "Chemistry", "Physics", "Mathematics",
    "Computer Science", "Mechanical Engineering",
]

baseline_rates = {}
for disc in DISCIPLINES:
    ctrl = df[(df["discipline"] == disc) & (df["treatment"] == 0)]
    baseline_rates[disc] = ctrl["pct_black"].mean() if len(ctrl) > 0 else 0
groups = sorted(DISCIPLINES, key=lambda d: baseline_rates[d])


def get_usable_controls(data, controls):
    """Return controls that have sufficient variation in the data subset."""
    usable = []
    for ctrl in controls:
        if ctrl in data.columns:
            vals = data[ctrl].dropna()
            if len(vals.unique()) > 1:
                usable.append(ctrl)
    return usable


def ols_cluster(formula, data):
    """Run OLS with clustered SEs. Returns None if insufficient data."""
    lhs, rhs = formula.split("~")
    vars_ = [v.strip() for v in (lhs + rhs).split("+")]
    vars_ = [v for v in vars_ if v in data.columns]
    d = data.dropna(subset=vars_)
    if len(d) < 10:
        return None, None, d
    try:
        m = smf.ols(formula, data=d).fit()
        if d["department_std"].nunique() > 1:
            cov = sm.stats.sandwich_covariance.cov_cluster(m, d["department_std"])
            se = np.sqrt(np.diag(cov))
        else:
            se = m.bse.values
        return m, se, d
    except Exception:
        return None, None, d


def stars(p):
    if p < 0.001:
        return "***"
    if p < 0.01:
        return "**"
    if p < 0.05:
        return "*"
    return ""


# Panel specifications — all for Black speakers
panels = {
    "A": {
        "title": "% of Speakers Who Were\nBlack",
        "dv": "pct_black",
        "mode": "pct",
        "xlabel": "% of Seminar Speakers",
        "fmt_val": "{:.1f}%",
        "fmt_delta": "\u0394 = {:+.2f}%",
    },
    "B": {
        "title": "# of Speakers Who Were\nBlack",
        "dv": "num_black",
        "mode": "count",
        "xlabel": "Speakers per Seminar",
        "fmt_val": "{:.2f}",
        "fmt_delta": "\u0394 = {:+.2f}",
    },
    "C": {
        "title": "% of Seminars with Any\nBlack Speakers",
        "dv": "has_any_black",
        "mode": "pct_binary",
        "xlabel": "% of Seminars",
        "fmt_val": "{:.1f}%",
        "fmt_delta": "\u0394 = {:+.2f}%",
    },
}


def compute_panel_data(panel_spec):
    results = []
    dv = panel_spec["dv"]
    mode = panel_spec["mode"]

    for disc in groups:
        disc_df = df[df["discipline"] == disc].copy()
        n_treat_disc = (disc_df["treatment"] == 1).sum()
        n_ctrl_disc = (disc_df["treatment"] == 0).sum()

        c_vals = disc_df.loc[disc_df.treatment == 0, dv]
        t_vals = disc_df.loc[disc_df.treatment == 1, dv]

        # Try OLS with controls
        usable = get_usable_controls(disc_df, all_controls)
        if usable:
            formula = f"{dv} ~ treatment + " + " + ".join(usable)
        else:
            formula = f"{dv} ~ treatment"

        model, se_vec, d = ols_cluster(formula, disc_df)

        if model is not None and "treatment" in model.params.index:
            t_coef = model.params["treatment"]
            t_se_cl = se_vec[model.params.index.get_loc("treatment")]
            clusters = d["department_std"].nunique()
            dof = max(clusters - 1, 1)
            p_val = 2 * (1 - stats.t.cdf(abs(t_coef / t_se_cl), dof))

            # Regression-adjusted means
            pred_data = pd.DataFrame({"treatment": [0, 1]})
            for ctrl in usable:
                if ctrl in disc_df.columns:
                    pred_data[ctrl] = disc_df[ctrl].mean()
            preds = model.predict(pred_data)

            if mode == "total":
                c_display = preds.iloc[0] * n_ctrl_disc
                t_display = preds.iloc[1] * n_treat_disc
                c_se = c_vals.sem() * n_ctrl_disc
                t_se = t_vals.sem() * n_treat_disc
                delta = t_display - c_display
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
        else:
            # Fallback: raw means
            c_mean = c_vals.mean() if len(c_vals) > 0 else 0
            t_mean = t_vals.mean() if len(t_vals) > 0 else 0
            if len(c_vals) > 1 and len(t_vals) > 1:
                _, p_val = stats.ttest_ind(t_vals, c_vals, equal_var=False)
            else:
                p_val = 1.0
            delta_raw = t_mean - c_mean

            if mode == "total":
                c_display = c_mean * n_ctrl_disc
                t_display = t_mean * n_treat_disc
                c_se = c_vals.sem() * n_ctrl_disc if len(c_vals) > 1 else 0
                t_se = t_vals.sem() * n_treat_disc if len(t_vals) > 1 else 0
                delta = t_display - c_display
            elif mode == "pct_binary":
                c_display = c_mean * 100
                t_display = t_mean * 100
                c_se = c_vals.sem() * 100 if len(c_vals) > 1 else 0
                t_se = t_vals.sem() * 100 if len(t_vals) > 1 else 0
                delta = delta_raw * 100
            else:
                c_display = c_mean
                t_display = t_mean
                c_se = c_vals.sem() if len(c_vals) > 1 else 0
                t_se = t_vals.sem() if len(t_vals) > 1 else 0
                delta = delta_raw

        results.append({
            "group": disc,
            "c_val": c_display, "t_val": t_display,
            "c_se": c_se, "t_se": t_se,
            "delta": delta, "p": p_val,
        })
    return results


# ── Layout constants ──
bar_height = 0.30
group_spacing = 1.4
ctrl_offset = 0.42
treat_offset = 0.80
header_band_half = 0.15

# ── Create the figure ──
fig, axes = plt.subplots(1, 3, figsize=(22, 12))
plt.subplots_adjust(wspace=0.35)

for ax_idx, (panel_key, panel_spec) in enumerate(panels.items()):
    ax = axes[ax_idx]
    data = compute_panel_data(panel_spec)

    # ── Pass 1: draw header bands and bars ──
    for grp_idx, row in enumerate(data):
        base = grp_idx * group_spacing
        ctrl_y = base + ctrl_offset
        treat_y = base + treat_offset

        # Gray header band with discipline name
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
    ax.set_xlim(xlim_auto[0], x_extent * 1.25)

    # ── Pass 2: text labels and annotations ──
    for grp_idx, row in enumerate(data):
        base = grp_idx * group_spacing
        ctrl_y = base + ctrl_offset
        treat_y = base + treat_offset
        c_val, t_val = row["c_val"], row["t_val"]

        # Discipline name centered in header band
        ax.text(
            0.38, base, row["group"],
            transform=ax.get_yaxis_transform(),
            ha="center", va="center",
            fontsize=18, fontweight="bold", color=WHARTON_DARK_GRAY, zorder=1,
        )

        # Value labels inside bars
        ax.text(
            c_val / 2, ctrl_y,
            panel_spec["fmt_val"].format(c_val),
            ha="center", va="center", fontsize=16, fontweight="bold",
            color="white", zorder=3,
        )
        ax.text(
            t_val / 2, treat_y,
            panel_spec["fmt_val"].format(t_val),
            ha="center", va="center", fontsize=16, fontweight="bold",
            color="white", zorder=3,
        )

        # Significance annotation
        if row["p"] < 0.05:
            xmax = max(c_val + row["c_se"], t_val + row["t_se"])
            mid_y = base + (ctrl_offset + treat_offset) / 2
            sig = stars(row["p"])
            delta_label = panel_spec["fmt_delta"].format(row["delta"])
            ax.text(
                xmax + x_extent * 0.03, mid_y,
                f"{delta_label} {sig}",
                ha="left", va="center", fontsize=17, fontweight="bold",
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
    ax.set_yticklabels(yticklabels, fontsize=16)
    ax.tick_params(axis="y", length=0, pad=4)

    # X-axis formatting
    if panel_spec["mode"] in ("pct", "pct_binary"):
        ax.xaxis.set_major_formatter(FuncFormatter(lambda x, p: f"{x:.0f}%"))

    # Y-axis limits
    y_top = -header_band_half - 0.06
    y_bottom = (
        (len(groups) - 1) * group_spacing + treat_offset + bar_height / 2 + 0.06
    )
    ax.set_ylim(y_top, y_bottom)

    # Panel title and x-axis label
    ax.set_title(
        f"{panel_key}.  {panel_spec['title']}",
        fontsize=20, fontweight="bold", pad=14, loc="left",
    )
    ax.set_xlabel(panel_spec["xlabel"], fontsize=18, fontweight="bold")

    # Spines
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.spines["left"].set_color(WHARTON_DARK_GRAY)
    ax.spines["bottom"].set_color(WHARTON_DARK_GRAY)
    ax.spines["left"].set_linewidth(1.4)
    ax.spines["bottom"].set_linewidth(1.4)

    ax.invert_yaxis()

plt.tight_layout()

out_path = os.path.join(OUT_DIR, "figure_s5.png")
plt.savefig(out_path, dpi=600, bbox_inches="tight", facecolor="white")
plt.close()
print(f"Figure S5 saved to: {out_path}")
