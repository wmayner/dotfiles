"""House style, palette, direct labels and a clutter check for matplotlib figures.

    import figkit as fk
    fk.use()                          # style and font; call after any sns.set_theme
    fig, ax = plt.subplots()          # default size suits a slide or a page column
    ax.plot(x, a, color=fk.ACCENT, label="conditioned")
    ax.plot(x, b, color=fk.GREY, label="gradient")
    fk.label_lines(ax)                # names at the line ends, no legend
    fk.save(fig, "fig1.png")          # runs check() and prints what to fix

Single file on purpose: copy it next to a figure script when the code must run
somewhere without ~/.claude (fonts then fall back to DejaVu Sans).
"""
from pathlib import Path

import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib import font_manager, ticker
from matplotlib.text import Text

INK = "#1F1F1F"       # text and the most important dark mark
MUTED = "#6B6B6B"     # axis lines, tick labels, secondary text
GREY = "#A3A3A3"      # context series
LIGHT = "#D9D9D9"     # bands, reference regions, de-emphasised bars
ACCENT = "#D55E00"    # the one thing the figure is about (Okabe-Ito vermillion)
BLUE = "#0072B2"      # a second highlighted series, if the claim contrasts two
# Okabe-Ito, colour-blind safe; use only when the categories themselves are the point.
CATEGORICAL = ["#0072B2", "#D55E00", "#009E73", "#CC79A7", "#E69F00", "#56B4E9"]

_FONTS = [Path(__file__).with_name("fonts"), Path.home() / ".claude/skills/figures/fonts"]

STYLE = {
    "figure.figsize": (7, 4),
    "figure.dpi": 100,
    "figure.constrained_layout.use": True,
    "figure.facecolor": "white",
    "savefig.dpi": 200,
    "savefig.facecolor": "white",
    "font.size": 13,
    "axes.labelsize": 13,
    "axes.titlesize": 13,
    "axes.titleweight": "semibold",
    "axes.titlelocation": "left",
    "axes.titlepad": 8,
    "xtick.labelsize": 12,
    "ytick.labelsize": 12,
    "legend.fontsize": 12,
    "legend.frameon": False,
    "text.color": INK,
    "axes.labelcolor": INK,
    "axes.edgecolor": MUTED,
    "axes.linewidth": 0.9,
    "axes.spines.top": False,
    "axes.spines.right": False,
    "axes.grid": True,
    "axes.grid.axis": "y",
    "grid.color": "#ECECEC",
    "grid.linewidth": 0.8,
    "axes.axisbelow": True,
    "axes.prop_cycle": mpl.cycler(color=CATEGORICAL),
    "xtick.color": MUTED,
    "ytick.color": MUTED,
    "xtick.labelcolor": INK,
    "ytick.labelcolor": INK,
    "lines.linewidth": 2.2,
    "lines.markersize": 6,
    "errorbar.capsize": 0,
    "patch.edgecolor": "none",
}


def use():
    """Apply the house style. Call after seaborn's set_theme, or instead of it."""
    for d in _FONTS:
        for f in sorted(d.glob("*.ttf")) if d.is_dir() else []:
            font_manager.fontManager.addfont(str(f))
    have_inter = any(f.name == "Inter" for f in font_manager.fontManager.ttflist)
    mpl.rcParams.update(STYLE)
    mpl.rcParams["font.family"] = "sans-serif"
    mpl.rcParams["font.sans-serif"] = (["Inter"] if have_inter else []) + ["DejaVu Sans"]


def label_lines(ax, lines=None, gap=1.25, pad=6):
    """Write each labelled line's name at its right end, in its colour, and drop the legend.

    Labels that would collide are pushed apart vertically. Lines whose label starts with "_" are skipped.
    """
    lines = [l for l in (lines or ax.get_lines()) if not l.get_label().startswith("_")]
    ax.figure.canvas.draw()
    ends = []
    for l in lines:
        x, y = l.get_xdata(), l.get_ydata()
        ok = [i for i in range(len(x)) if x[i] == x[i] and y[i] == y[i]]  # drop NaN
        if ok:
            px, py = ax.transData.transform((x[ok[-1]], y[ok[-1]]))
            ends.append([py, px, l])
    ends.sort(key=lambda e: e[0])
    step = mpl.rcParams["font.size"] * gap * ax.figure.dpi / 72
    for i in range(1, len(ends)):  # push colliding labels upward
        ends[i][0] = max(ends[i][0], ends[i - 1][0] + step)
    inv = ax.transData.inverted()
    for py, px, l in ends:
        x, y = inv.transform((px, py))
        ax.annotate(l.get_label(), (x, y), xytext=(pad, 0), textcoords="offset points",
                    color=l.get_color(), va="center", ha="left", annotation_clip=False)
    if ax.get_legend():
        ax.get_legend().remove()


def label_bars(ax, pad=4):
    """Name each bar series above its first bar (in its colour, or grey if the bar is pale) and drop the legend.

    Works with seaborn's barplot(hue=...) and with repeated ax.bar(..., label=...) calls.
    """
    from matplotlib.container import BarContainer
    bars = [c for c in ax.containers if isinstance(c, BarContainer) and len(c.patches)]
    lg = ax.get_legend()
    names = [t.get_text() for t in lg.get_texts()] if lg else [c.get_label() for c in bars]
    for c, name in zip(bars, names):
        b = c.patches[0]
        cx = b.get_x() + b.get_width() / 2
        top = b.get_y() + b.get_height()
        for l in ax.get_lines():  # sit above an error bar drawn at this bar
            x = l.get_xdata()
            if len(x) == 2 and abs(x[0] - cx) < 1e-6 * max(1, abs(cx)):
                top = max(top, *l.get_ydata())
        r, g, b_, _ = mpl.colors.to_rgba(b.get_facecolor())
        color = MUTED if 0.299 * r + 0.587 * g + 0.114 * b_ > 0.75 else b.get_facecolor()
        ax.annotate(name, (cx, top), xytext=(0, pad), textcoords="offset points",
                    ha="center", va="bottom", color=color, annotation_clip=False)
    if lg:
        lg.remove()


def plain_ticks(axis):
    """Plain numbers (1, 10, 100, 0.01) instead of powers of ten on a log axis: plain_ticks(ax.yaxis)."""
    axis.set_major_formatter(ticker.FuncFormatter(lambda v, _: f"{v:g}"))
    axis.set_minor_formatter(ticker.NullFormatter())


def check(fig, words=25, min_pt=10, max_series=5, max_panels=4, title_words=6):
    """Return a list of problems: too much text, sentence titles, boxed text, legends that
    could be direct labels, crowded panels, small fonts, overlapping or clipped text."""
    fig.canvas.draw()
    r = fig.canvas.get_renderer()
    axes = [a for a in fig.axes if a.get_label() != "<colorbar>"]
    ticks, hidden = set(), set()
    for a in fig.axes:
        for ax_, i in ((a.xaxis, 0), (a.yaxis, 1)):
            lo, hi = sorted(ax_.get_view_interval())
            for t in ax_.get_ticklabels(which="both"):  # labels of ticks outside the view are not drawn
                (ticks if lo - 1e-9 * abs(hi - lo) <= t.get_position()[i] <= hi + 1e-9 * abs(hi - lo) else hidden).add(t)
            ticks.add(ax_.get_offset_text())
    texts = [t for t in fig.findobj(Text) if t.get_visible() and t.get_text().strip() and t not in hidden]
    free = [t for t in texts if t not in ticks]
    n_words = sum(len(t.get_text().split()) for t in free)
    out = []
    budget = words + 10 * (len(axes) - 1)
    if n_words > budget:
        out.append(f"{n_words} words of text outside tick labels (budget {budget}): move definitions, "
                   "statistics and the claim into the caption")
    if fig._suptitle is not None and fig._suptitle.get_text().strip():
        out.append(f"suptitle {fig._suptitle.get_text()[:60]!r}: put the claim in the caption or heading, not the image")
    for a in axes:
        for loc in ("left", "center", "right"):
            n = len(a.get_title(loc).split())
            if n > title_words:
                out.append(f"panel title of {n} words {a.get_title(loc)[:50]!r}: name the panel in ≤ {title_words} words")
    boxed = [t.get_text()[:40] for t in free if t.get_bbox_patch() is not None]
    if boxed:
        out.append(f"text in boxes {boxed}: no annotation boxes; label the mark directly or use the caption")
    legends = [a.get_legend() for a in fig.axes if a.get_legend()] + list(fig.legends)
    for lg in legends:
        if len(lg.get_texts()) > 4:
            out.append(f"legend with {len(lg.get_texts())} entries: cut series, or grey the context and label directly")
        elif any(isinstance(h, mpl.lines.Line2D) and h.get_linestyle() not in ("None", "")
                 for h in lg.legend_handles):
            out.append("legend for lines: use fk.label_lines(ax) to name them at their ends")
    if len(axes) > max_panels:
        out.append(f"{len(axes)} panels: is this a table drawn as a plot? Show the one comparison the claim needs")
    for a in axes:
        n = len([l for l in a.get_lines() if not l.get_label().startswith("_")]) + len(a.containers)
        if n > max_series:
            out.append(f"panel {a.get_title() or a.get_ylabel()!r} has {n} series: keep ≤ {max_series - 1}, grey the rest")
    small = sorted({round(t.get_fontsize(), 1) for t in texts if t.get_fontsize() < min_pt})
    if small:
        out.append(f"font sizes {small} pt below {min_pt} pt")
    w, h = fig.get_size_inches()
    if w > 10:
        out.append(f"figure is {w:.1f} in wide: everything shrinks when it is scaled to a slide; keep ≤ 10 in")
    boxes = [(t, t.get_window_extent(r)) for t in texts]
    fb = fig.bbox
    clipped = [t.get_text()[:30] for t, b in boxes if b.x0 < fb.x0 - 1 or b.x1 > fb.x1 + 1 or b.y0 < fb.y0 - 1 or b.y1 > fb.y1 + 1]
    if clipped:
        out.append(f"text cut off at the figure edge: {clipped[:5]}")
    hits = []
    for i, (t1, b1) in enumerate(boxes):
        for t2, b2 in boxes[i + 1:]:
            if b1.width and b2.width and b1.padded(-1).overlaps(b2.padded(-1)):
                hits.append((t1.get_text()[:20], t2.get_text()[:20]))
    if hits:
        out.append(f"{len(hits)} overlapping text pairs, e.g. {hits[:3]}")
    if any(len(t.get_text()) > 3 and t.get_rotation() not in (0, 90, 270) for t in ticks if t.get_visible()):
        out.append("rotated tick labels: shorten them, or swap axes so the labels run horizontally")
    seen = {}
    for m in out:  # one line per kind of problem
        seen[m] = seen.get(m, 0) + 1
    return [m if n == 1 else f"{m} (x{n})" for m, n in seen.items()]


def save(fig, path, **check_kw):
    """Check the figure, print what to fix, and save it. Extension sets the format; PNG at 200 dpi by default."""
    problems = check(fig, **check_kw)
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(path)
    if problems:
        print(f"FIGURE CHECK {path.name}: {len(problems)} to fix before anyone sees it")
        for p in problems:
            print("  -", p)
    else:
        print(f"FIGURE CHECK {path.name}: ok")
    return problems


if __name__ == "__main__":  # self-check: a cluttered figure fails, a clean one passes
    import numpy as np
    mpl.use("Agg")
    use()
    x = np.arange(1, 20)
    fig, axs = plt.subplots(2, 3, figsize=(14, 7))
    fig.suptitle("Methods differ in how fast the error falls when the top k candidates are kept and the rest ablated")
    for a in axs.flat:
        for i in range(7):
            a.plot(x, x ** -(0.2 * i + 0.3), label=f"method {i}")
        a.text(5, 0.5, "BF10 = 1e+251 | 1e+252 meaningful", bbox=dict(fc="w"))
        a.legend()
    bad = check(fig)
    assert len(bad) >= 6, bad
    fig, ax = plt.subplots()
    ax.plot(x, x ** -0.9, color=ACCENT, label="conditioned")
    ax.plot(x, x ** -0.4, color=GREY, label="gradient")
    label_lines(ax)
    ax.set(xlabel="Units kept", ylabel="Error left in the target")
    assert check(fig) == [], check(fig)
    print("figkit self-check ok;", len(bad), "problems found in the cluttered figure")
