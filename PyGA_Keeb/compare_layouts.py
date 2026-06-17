"""Compare typing-effort fitness across multiple keyboard layouts.

Loads this project's GA-optimized layouts (PyGA_Keeb/results/run-*/best_layout.txt)
and the R LEGS reference layouts (R LEGS/layouts/*.txt), scores every one with the
same fitness function (fitness.compute_fitness) using the same corpus n-gram data,
*ignoring* any optional constraints (constraints.py) so the comparison is purely on
modeled typing effort -- then plots a sorted, zoomed dot chart.

R LEGS layout files use '-' as their 30th character; this project's CHARACTERS tuple
uses "'" in that slot (see keyboard.py's note on this), so '-' is translated to "'"
on load.

Usage:
    python3.9 compare_layouts.py
    python3.9 compare_layouts.py --layout mine=results/run-.../best_layout.txt --layout qwerty=../R\\ LEGS/layouts/qwerty.txt
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Dict, List, Tuple

from fitness import Layout, compute_fitness
from keyboard import CHARACTERS

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_RESULTS_DIR = Path(__file__).resolve().parent / "results"
DEFAULT_R_LEGS_LAYOUTS_DIR = PROJECT_ROOT / "R LEGS" / "layouts"

CHAR_SET = set(CHARACTERS)


def load_layout(path: Path) -> Layout:
    """Read a layout file (one row per line, space-separated or bare characters)."""
    raw = path.read_text(encoding="utf-8")
    chars: List[str] = []
    for line in raw.splitlines():
        line = line.strip()
        if not line:
            continue
        tokens = line.split() if " " in line else list(line)
        chars.extend(tokens)
    chars = ["'" if ch == "-" else ch for ch in chars]
    layout = tuple(chars)
    if len(layout) != len(CHARACTERS) or set(layout) != CHAR_SET:
        raise ValueError(f"{path}: not a valid permutation of {''.join(CHARACTERS)} (got {''.join(layout)})")
    return layout


def discover_default_layouts() -> Dict[str, Path]:
    paths: Dict[str, Path] = {}
    for run_dir in sorted(DEFAULT_RESULTS_DIR.glob("run-*")):
        layout_file = run_dir / "best_layout.txt"
        if layout_file.exists():
            paths[f"ga/{run_dir.name}"] = layout_file
    for layout_file in sorted(DEFAULT_R_LEGS_LAYOUTS_DIR.glob("*.txt")):
        paths[f"r_legs/{layout_file.stem}"] = layout_file
    return paths


def plot_comparison(results: List[Tuple[str, float, float, Layout]], output_path: Path) -> None:
    """Dot plot, zoomed to the main cluster of close-scoring layouts.

    A bar chart must start at 0 to honestly represent magnitude, which makes
    differences between close-scoring layouts invisible. Dots can be zoomed
    safely since they encode position, not area. ``results`` is
    ``(name, fitness, fitness_without_orders_4_5, layout)``, sorted ascending
    by ``fitness`` (best first).

    A few much-worse layouts (e.g. plain QWERTY) would otherwise stretch the
    x-axis and re-compress the interesting cluster, so the visible range is
    capped at a Tukey upper fence (Q3 + 1.5*IQR) over the *full* fitness
    values: anything beyond that is drawn clipped at the right edge (arrow
    marker, real value annotated "off-scale") instead of being plotted at
    true scale. Gaps between consecutive *in-view* layouts that are more
    than 2x the average in-view gap are shaded and labelled -- those are the
    "big gap" tier boundaries.

    Each layout also gets a second, grayed-out reference dot directly below
    its main dot: the same fitness recomputed with orders 4/5 forced to
    weight 0 (i.e. ignoring the 12x-weighted full-hand-alternation /
    full-hand-monopoly penalties). A thin gray line connects the two, so the
    horizontal gap between them is a direct visual read of how much orders
    4/5 are currently moving that layout's score.
    """
    import statistics

    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.patches as mpatches
    import matplotlib.pyplot as plt

    names = [r[0] for r in results]
    fitnesses = [r[1] for r in results]
    fitnesses_no45 = [r[2] for r in results]
    colors = ["tab:blue" if nm.startswith("r_legs/") else "tab:orange" for nm in names]
    n = len(results)
    y = list(range(n - 1, -1, -1))  # best (lowest fitness) at the top
    y_offset = 0.28  # vertical drop for the grayed "without orders 4/5" reference dot

    if n >= 4:
        q1, _, q3 = statistics.quantiles(fitnesses, n=4)
        upper_fence = q3 + 1.5 * (q3 - q1)
    else:
        upper_fence = max(fitnesses)
    xmin = min(min(fitnesses), min(fitnesses_no45))
    xmax = min(upper_fence, max(fitnesses))
    span = max(xmax - xmin, 1e-6)
    pad = span * 0.15
    edge_x = xmax + pad * 0.5

    fig, ax = plt.subplots(figsize=(9, max(4, 0.45 * n)))

    def clipped(x: float) -> Tuple[float, bool]:
        return (x, False) if x <= xmax else (edge_x, True)

    n_off_scale = 0
    in_view_fitnesses: List[float] = []
    in_view_y: List[int] = []
    for fx, fx45, fy, c in zip(fitnesses, fitnesses_no45, y, colors):
        fx_plot, fx_off = clipped(fx)
        fx45_plot, fx45_off = clipped(fx45)

        ax.plot([fx45_plot, fx_plot], [fy - y_offset, fy], color="lightgray", linewidth=1, zorder=1)

        if fx_off:
            n_off_scale += 1
            ax.scatter(fx_plot, fy, c=c, s=70, zorder=3, marker=">")
            ax.text(fx_plot, fy, f"  {fx:.4f} (off-scale)", va="center", fontsize=8, color="dimgray", zorder=3)
        else:
            ax.scatter(fx_plot, fy, c=c, s=70, zorder=3)
            ax.text(fx_plot, fy, f"  {fx:.4f}", va="center", fontsize=8, zorder=3)
            in_view_fitnesses.append(fx)
            in_view_y.append(fy)

        marker45 = ">" if fx45_off else "o"
        ax.scatter(fx45_plot, fy - y_offset, c="darkgray", s=30, alpha=0.6, zorder=2, marker=marker45)
        ax.text(
            fx45_plot,
            fy - y_offset,
            f"  {fx45:.4f}" + (" (off-scale)" if fx45_off else ""),
            va="center",
            fontsize=7,
            color="gray",
            zorder=2,
        )

    ax.set_yticks(y)
    ax.set_yticklabels(names)
    ax.set_xlim(xmin - pad, xmax + pad * 2.6)
    if n_off_scale:
        ax.axvline(xmax + pad * 0.15, color="gray", linestyle=":", linewidth=1, zorder=2)

    gaps = [in_view_fitnesses[i + 1] - in_view_fitnesses[i] for i in range(len(in_view_fitnesses) - 1)]
    if gaps:
        mean_gap = sum(gaps) / len(gaps)
        for i, gap in enumerate(gaps):
            if gap > 2 * mean_gap:
                ax.axhspan(in_view_y[i + 1] - 0.5, in_view_y[i] + 0.5, color="red", alpha=0.06, zorder=0)
                ax.annotate(
                    f"gap +{gap:.4f}",
                    xy=(in_view_fitnesses[i], (in_view_y[i] + in_view_y[i + 1]) / 2),
                    xytext=(10, 0),
                    textcoords="offset points",
                    color="firebrick",
                    fontsize=8,
                    va="center",
                    fontweight="bold",
                )

    ax.grid(axis="x", linestyle="--", alpha=0.4, zorder=0)
    ax.set_xlabel("fitness (lower is better; constraints excluded; zoomed to main cluster)")
    title = "Layout fitness comparison (zoomed)"
    if n_off_scale:
        title += f" -- {n_off_scale} layout(s) off-scale at right edge"
    ax.set_title(title)
    legend_handles = [
        mpatches.Patch(color="tab:orange", label="this project's GA runs"),
        mpatches.Patch(color="tab:blue", label="R LEGS reference layouts"),
        mpatches.Patch(color="darkgray", alpha=0.6, label="same layout, orders 4/5 weight=0 (reference)"),
    ]
    ax.legend(handles=legend_handles, loc="upper center", bbox_to_anchor=(0.5, -0.04), ncol=1, frameon=True)
    fig.tight_layout()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path, bbox_inches="tight")
    plt.close(fig)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ngram-data", default="data/ngram_counts.json")
    parser.add_argument("--config", default="config.yaml")
    parser.add_argument(
        "--layout",
        action="append",
        default=[],
        metavar="NAME=PATH",
        help="Add an explicit layout file as NAME=PATH (repeatable). If omitted, "
        "auto-discovers results/run-*/best_layout.txt and 'R LEGS/layouts/*.txt'.",
    )
    parser.add_argument("--output", default="results/layout_comparison.png")
    args = parser.parse_args()

    import yaml

    cfg = yaml.safe_load(Path(args.config).read_text())
    top_n = {int(k): v for k, v in cfg["fitness"]["top_n"].items()}
    weights = {int(k): v for k, v in cfg["fitness"].get("weights", {}).items()}
    allow_swipe_motions = cfg["fitness"].get("allow_swipe_motions", True)
    ngram_data = json.loads(Path(args.ngram_data).read_text())["counts"]

    if args.layout:
        layouts = {}
        for entry in args.layout:
            name, path = entry.split("=", 1)
            layouts[name] = Path(path)
    else:
        layouts = discover_default_layouts()

    weights_no45 = {**weights, 4: 0.0, 5: 0.0}

    results: List[Tuple[str, float, float, Layout]] = []
    for name, path in layouts.items():
        try:
            layout = load_layout(path)
        except ValueError as exc:
            print(f"skipping {name}: {exc}")
            continue
        # constraints intentionally excluded
        fit = compute_fitness(layout, ngram_data, weights, top_n, allow_swipe_motions=allow_swipe_motions)
        fit_no45 = compute_fitness(layout, ngram_data, weights_no45, top_n, allow_swipe_motions=allow_swipe_motions)
        results.append((name, fit, fit_no45, layout))

    results.sort(key=lambda r: r[1])

    print(f"{'layout':35s} {'fitness':>10s} {'no_orders_4_5':>14s}")
    for name, fit, fit_no45, _ in results:
        print(f"{name:35s} {fit:10.4f} {fit_no45:14.4f}")

    plot_comparison(results, Path(args.output))
    print(f"\nPlot saved to {args.output}")


if __name__ == "__main__":
    main()
