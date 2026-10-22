"""
make_charts.py
Turns the CSV results of your SQL queries into clean PNG charts for the
README and the portfolio website.

Usage:
    1. Export each query result to results/ as CSV.
    2. Edit the calls at the bottom of this file (file names, column names,
       and a title that states the finding).
    3. Run:  python charts/make_charts.py

Two chart types cover most findings:
    line_chart  - one value over time (monthly revenue, orders)
    bar_chart   - one value across categories (states, delay buckets)
"""

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
RESULTS = ROOT / "results"
CHARTS = ROOT / "charts"

# Colours: one accent for the data, grey for context, dark ink for text.
ACCENT = "#2a78d6"       # main series
HIGHLIGHT = "#eb6834"    # the one bar you want readers to notice
MUTED = "#c9c8c3"        # other bars when one is highlighted
INK = "#0b0b0b"
INK_SOFT = "#52514e"
GRID = "#e6e5e1"
SOURCE = "Source: Olist Brazilian E-Commerce Public Dataset (Kaggle)"

plt.rcParams.update({
    "font.family": "DejaVu Sans",
    "font.size": 11,
    "axes.edgecolor": GRID,
    "axes.labelcolor": INK_SOFT,
    "xtick.color": INK_SOFT,
    "ytick.color": INK_SOFT,
    "axes.spines.top": False,
    "axes.spines.right": False,
})


def _finish(fig, ax, title, subtitle, out_name):
    """Shared layout: finding as title, units as subtitle, source at the foot."""
    fig.suptitle(title, x=0.01, ha="left", fontsize=14, fontweight="bold", color=INK)
    if subtitle:
        ax.set_title(subtitle, loc="left", fontsize=11, color=INK_SOFT, pad=12)
    fig.supxlabel(SOURCE, x=0.01, ha="left", fontsize=9, color=INK_SOFT)
    CHARTS.mkdir(exist_ok=True)
    out = CHARTS / out_name
    fig.savefig(out, dpi=200, facecolor="white")
    plt.close(fig)
    print(f"Saved {out}")


def line_chart(csv_name, x, y, title, out_name, subtitle=None, value_format="{:,.0f}"):
    """One value over time. The last point is labelled directly."""
    df = pd.read_csv(RESULTS / csv_name, parse_dates=[x]).sort_values(x)
    fig, ax = plt.subplots(figsize=(9, 5), constrained_layout=True)
    ax.plot(df[x], df[y], color=ACCENT, linewidth=2)
    ax.scatter(df[x].iloc[-1], df[y].iloc[-1], color=ACCENT, s=36, zorder=3)
    ax.annotate(value_format.format(df[y].iloc[-1]),
                (df[x].iloc[-1], df[y].iloc[-1]),
                xytext=(6, 0), textcoords="offset points",
                va="center", color=INK, fontsize=10)
    ax.grid(axis="y", color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)
    ax.set_ylim(bottom=0)
    ax.yaxis.set_major_formatter(plt.FuncFormatter(lambda v, _: f"{v:,.0f}"))
    ax.set_xlabel("")
    _finish(fig, ax, title, subtitle, out_name)


def bar_chart(csv_name, category, value, title, out_name, subtitle=None,
              highlight=None, sort=True, value_format="{:,.1f}"):
    """One value across categories, as horizontal bars with values at the ends.

    highlight: a category name, or a list of names, to colour orange while
               the rest turn grey.
    sort:      True sorts largest at the top; False keeps the CSV order
               (use False for ordered buckets such as delivery delay).
    """
    df = pd.read_csv(RESULTS / csv_name)
    if sort:
        df = df.sort_values(value)
    else:
        df = df.iloc[::-1]  # first CSV row ends up at the top
    labels = df[category].astype(str)
    if highlight is None:
        colours = [ACCENT] * len(df)
    else:
        if isinstance(highlight, (list, tuple, set)):
            keep = {str(h) for h in highlight}
        else:
            keep = {str(highlight)}
        colours = [HIGHLIGHT if c in keep else MUTED for c in labels]

    fig, ax = plt.subplots(figsize=(9, max(3.5, 0.45 * len(df) + 1.8)), constrained_layout=True)
    bars = ax.barh(labels, df[value], color=colours, height=0.7)
    for bar, v in zip(bars, df[value]):
        ax.text(bar.get_width(), bar.get_y() + bar.get_height() / 2,
                " " + value_format.format(v), va="center", color=INK, fontsize=10)
    ax.grid(axis="x", color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)
    ax.spines["left"].set_visible(False)
    ax.tick_params(axis="y", length=0)
    ax.set_xlim(0, df[value].max() * 1.15)
    ax.xaxis.set_major_formatter(plt.FuncFormatter(lambda v, _: f"{v:,.0f}"))
    _finish(fig, ax, title, subtitle, out_name)


if __name__ == "__main__":
    # Q1A: monthly revenue trend
    line_chart("q1a_monthly_revenue.csv", x="month", y="revenue",
               title="Revenue grew 141% year on year, driven by more orders",
               subtitle="Monthly revenue from delivered orders, BRL, Jan 2017 to Aug 2018",
               out_name="q1_monthly_revenue.png")

    # Q1B: categories behind the growth
    bar_chart("q1b_category_growth.csv", category="category", value="growth_abs",
              title="Five categories delivered 44% of revenue growth",
              subtitle="Revenue added, Jan to Aug 2018 against Jan to Aug 2017, BRL",
              out_name="q1b_category_growth.png", value_format="{:,.0f}")

    # Q3: delivery delay against 1-star reviews
    bar_chart("q3a_delay_vs_score.csv", category="delay_bucket", value="pct_1_star",
              title="70% of orders over a week late get a 1-star review",
              subtitle="Share of orders with a 1-star review, by delivery against the estimated date, %",
              out_name="q3_delay_vs_score.png", sort=False, value_format="{:.1f}%",
              highlight="More than 7 days late")

    # Q4: late-delivery rate by state
    bar_chart("q4a_state_performance.csv", category="customer_state", value="late_rate_pct",
              title="The five worst states for late delivery are all in the North-east",
              subtitle="Share of orders delivered after the estimated date, %, states with 300+ orders"
                       " (orange: worst five)",
              out_name="q4_late_rate_by_state.png", value_format="{:.1f}%",
              highlight=["AL", "MA", "SE", "PI", "CE"])
