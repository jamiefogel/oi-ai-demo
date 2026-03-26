#!/usr/bin/env python3
"""
Replicate formatted Opportunity Atlas mobility figures in Python.
"""

from pathlib import Path
from typing import Optional

import matplotlib.pyplot as plt
import numpy as np


REPO_ROOT = Path(__file__).resolve().parents[1]
INPUT_CSV = REPO_ROOT / "data" / "tract_outcomes" / "tract_outcomes_early.csv"
OUT_DIR = REPO_ROOT / "figures"
OUT_DIR.mkdir(parents=True, exist_ok=True)

# Style constants (matched to formatted R version)
BG_COLOR = "#ECECEC"
TEAL = "#25A391"
ORANGE = "#E2912D"
AXIS_GRAY = "#6F6F6F"
TEXT_DARK = "#1F1F1F"


def weighted_corr(x: np.ndarray, y: np.ndarray, w: np.ndarray) -> float:
    w = w / w.sum()
    mx = np.sum(w * x)
    my = np.sum(w * y)
    cov_xy = np.sum(w * (x - mx) * (y - my))
    cov_xx = np.sum(w * (x - mx) ** 2)
    cov_yy = np.sum(w * (y - my) ** 2)
    return cov_xy / np.sqrt(cov_xx * cov_yy)


def weighted_quantile(x: np.ndarray, w: np.ndarray, probs: np.ndarray) -> np.ndarray:
    order = np.argsort(x)
    x_sorted = x[order]
    w_sorted = w[order]
    cw = np.cumsum(w_sorted) / np.sum(w_sorted)
    idx = np.searchsorted(cw, probs, side="left")
    idx = np.clip(idx, 0, len(x_sorted) - 1)
    return x_sorted[idx]


def bin_scatter(x: np.ndarray, y: np.ndarray, w: np.ndarray, nbins: int = 20):
    probs = np.linspace(0, 1, nbins + 1)
    breaks = weighted_quantile(x, w, probs)
    breaks[0] = np.min(x)
    breaks[-1] = np.max(x)
    breaks = np.unique(breaks)
    if len(breaks) < 2:
        raise ValueError("Not enough unique x values to form bins.")

    # Use bin indices in 0...(k-1).
    bin_idx = np.digitize(x, breaks[1:-1], right=True)
    k = int(bin_idx.max()) + 1
    wsum = np.bincount(bin_idx, weights=w, minlength=k)
    xw = np.bincount(bin_idx, weights=x * w, minlength=k)
    yw = np.bincount(bin_idx, weights=y * w, minlength=k)
    keep = wsum > 0
    xb = xw[keep] / wsum[keep]
    yb = yw[keep] / wsum[keep]
    return xb, yb


def style_axes(ax: plt.Axes) -> None:
    ax.set_facecolor(BG_COLOR)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.spines["left"].set_color(AXIS_GRAY)
    ax.spines["bottom"].set_color(AXIS_GRAY)
    ax.tick_params(color=AXIS_GRAY, labelcolor=TEXT_DARK)
    ax.grid(False)


def make_scatter_plot(
    x: np.ndarray,
    y: np.ndarray,
    w: np.ndarray,
    title: str,
    subtitle: str,
    xlab: str,
    ylab: str,
    color: str,
    out_path: Path,
    nbins: Optional[int] = None,
) -> float:
    corr = weighted_corr(x, y, w)
    xlim = np.quantile(x, [0.005, 0.995])
    ylim = np.quantile(y, [0.005, 0.995])
    xlim = np.array([max(0.0, xlim[0]), min(1.0, xlim[1])])
    ylim = np.array([max(0.0, ylim[0]), min(1.0, ylim[1])])

    fig, ax = plt.subplots(figsize=(7.8, 5.1), dpi=150)
    fig.patch.set_facecolor(BG_COLOR)
    style_axes(ax)

    if nbins is None:
        ax.scatter(x, y, s=9, alpha=0.10, color=color)
        # Unweighted linear fit to match R geom_smooth default behavior.
        b1, b0 = np.polyfit(x, y, 1)
        xline = np.linspace(xlim[0], xlim[1], 200)
        yline = b1 * xline + b0
        ax.plot(xline, yline, color=color, linewidth=2.0)
    else:
        xb, yb = bin_scatter(x, y, w, nbins=nbins)
        ax.plot(xb, yb, color=color, linewidth=2.2)
        ax.scatter(xb, yb, s=35, color=color, zorder=3)

    ax.set_xlim(xlim[0], xlim[1])
    ax.set_ylim(ylim[0], ylim[1])
    ax.set_xlabel(xlab, fontsize=15, color=TEXT_DARK)
    ax.set_ylabel(ylab, fontsize=15, color=TEXT_DARK)
    ax.set_title(title, fontsize=20, color=color, pad=18)
    ax.text(
        0.5,
        1.005,
        subtitle,
        transform=ax.transAxes,
        ha="center",
        va="bottom",
        fontsize=14,
        color=TEXT_DARK,
        fontweight="bold",
    )
    ax.text(
        xlim[0] + 0.02 * (xlim[1] - xlim[0]),
        ylim[1] - 0.03 * (ylim[1] - ylim[0]),
        f"Weighted r = {corr:.3f}",
        ha="left",
        va="top",
        fontsize=14,
        color=TEXT_DARK,
        fontweight="bold",
    )
    fig.tight_layout()
    fig.savefig(out_path, facecolor=BG_COLOR)
    plt.close(fig)
    return corr


def main() -> None:
    colnames = [
        "state",
        "kfr_pooled_pooled_p25",
        "kfr_pooled_pooled_p75",
        "kfr_white_pooled_p25",
        "kfr_black_pooled_p25",
        "kid_pooled_pooled_blw_p50_n",
        "kid_white_pooled_blw_p50_n",
        "kid_black_pooled_blw_p50_n",
    ]
    with open(INPUT_CSV, "r", encoding="utf-8") as f:
        header = f.readline().strip().split(",")
    idx = [header.index(c) for c in colnames]

    usecols = tuple(idx)
    arr = np.genfromtxt(INPUT_CSV, delimiter=",", skip_header=1, usecols=usecols)

    state = arr[:, 0]
    kfr_p25 = arr[:, 1]
    kfr_p75 = arr[:, 2]
    kfr_w_p25 = arr[:, 3]
    kfr_b_p25 = arr[:, 4]
    w_pool = arr[:, 5]
    w_white = arr[:, 6]
    w_black = arr[:, 7]

    territories = np.isin(state, [60, 66, 69, 72, 78])
    keep_geo = ~territories

    pr_mask = keep_geo & ~np.isnan(kfr_p25) & ~np.isnan(kfr_p75) & ~np.isnan(w_pool) & (w_pool > 0)
    wb_weight = w_white + w_black
    wb_nonmissing = keep_geo & ~np.isnan(kfr_w_p25) & ~np.isnan(kfr_b_p25) & ~np.isnan(w_white) & ~np.isnan(w_black)
    wb_mask = wb_nonmissing.copy()
    wb_mask[wb_nonmissing] = wb_weight[wb_nonmissing] > 0

    corr_pr_raw = make_scatter_plot(
        kfr_p25[pr_mask],
        kfr_p75[pr_mask],
        w_pool[pr_mask],
        "Poor vs Rich Mobility",
        "Raw scatter",
        "Mean rank for children from p25 parents",
        "Mean rank for children from p75 parents",
        TEAL,
        OUT_DIR / "poor_rich_raw_python.pdf",
    )
    corr_pr_bin = make_scatter_plot(
        kfr_p25[pr_mask],
        kfr_p75[pr_mask],
        w_pool[pr_mask],
        "Poor vs Rich Mobility",
        "Binned scatter (20 weighted quantile bins)",
        "Mean rank for children from p25 parents",
        "Mean rank for children from p75 parents",
        TEAL,
        OUT_DIR / "poor_rich_bins_python.pdf",
        nbins=20,
    )
    corr_wb_raw = make_scatter_plot(
        kfr_w_p25[wb_mask],
        kfr_b_p25[wb_mask],
        wb_weight[wb_mask],
        "White vs Black Mobility (p25)",
        "Raw scatter",
        "Mean rank for white children",
        "Mean rank for Black children",
        ORANGE,
        OUT_DIR / "white_black_raw_python.pdf",
    )
    corr_wb_bin = make_scatter_plot(
        kfr_w_p25[wb_mask],
        kfr_b_p25[wb_mask],
        wb_weight[wb_mask],
        "White vs Black Mobility (p25)",
        "Binned scatter (20 weighted quantile bins)",
        "Mean rank for white children",
        "Mean rank for Black children",
        ORANGE,
        OUT_DIR / "white_black_bins_python.pdf",
        nbins=20,
    )

    print("Done. Python figure outputs:")
    print(OUT_DIR / "poor_rich_raw_python.pdf")
    print(OUT_DIR / "poor_rich_bins_python.pdf")
    print(OUT_DIR / "white_black_raw_python.pdf")
    print(OUT_DIR / "white_black_bins_python.pdf")
    print(f"Correlations: PR raw={corr_pr_raw:.3f}, PR bin={corr_pr_bin:.3f}, WB raw={corr_wb_raw:.3f}, WB bin={corr_wb_bin:.3f}")


if __name__ == "__main__":
    main()
