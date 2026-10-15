"""Line plot: one method highlighted, the rest grey, names at the line ends, no title.

Claim: the conditioned method needs far fewer units than the gradient baselines to bring the error under 0.1.
Caption (lives under the image, not in it): median error left in the target as units are kept, over 500
datapoints; dashed line at 0.1. Synthetic data.
"""
import os
import sys

import matplotlib.pyplot as plt
import numpy as np

sys.path.insert(0, os.path.expanduser("~/.claude/skills/figures"))
import figkit as fk

rng = np.random.default_rng(0)
k = np.unique(np.logspace(0, 3, 30).astype(int))
curves = {
    "gradient × activation": (0.9 * k ** -0.25, fk.GREY),
    "single ablation": (0.8 * k ** -0.35, fk.GREY),
    "conditioned": (0.7 * k ** -0.9, fk.ACCENT),
}
fk.use()
fig, ax = plt.subplots()
for name, (y, color) in curves.items():
    ax.plot(k, y * np.exp(rng.normal(0, 0.03, len(k))), color=color, label=name)
ax.axhline(0.1, color=fk.MUTED, lw=1, ls=":", zorder=0)
ax.set(xscale="log", yscale="log", xlabel="Units kept", ylabel="Error left in the target")
fk.plain_ticks(ax.xaxis)
fk.plain_ticks(ax.yaxis)
fk.label_lines(ax)
fk.save(fig, os.path.join(os.path.dirname(__file__), "line_direct_labels.png"))
