"""Bar plot: the comparison the claim is about, in four settings, with the method of interest in the accent colour.

Claim: conditioning on the target cuts the parents needed about fourfold in every layer.
Caption: geometric mean parents needed to reproduce the target activation, 95% bootstrap intervals over
700 datapoints per layer. Synthetic data.
"""
import os
import sys

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns

sys.path.insert(0, os.path.expanduser("~/.claude/skills/figures"))
import figkit as fk

rng = np.random.default_rng(0)
rows = []
for layer, base in zip(range(4), [42, 24, 26, 39]):
    for method, scale in [("standard", 1.0), ("conditioned", 0.22)]:
        for _ in range(700):
            rows.append(dict(layer=f"Layer {layer}", method=method, parents=base * scale * rng.lognormal(0, 0.4)))
df = pd.DataFrame(rows)

fk.use()
fig, ax = plt.subplots(figsize=(7, 4))
sns.barplot(df, x="layer", y="parents", hue="method", palette={"standard": fk.LIGHT, "conditioned": fk.ACCENT},
            estimator=lambda v: np.exp(np.log(v).mean()), errorbar=("ci", 95), seed=0, saturation=1,
            err_kws={"color": fk.MUTED, "lw": 1.2})
fk.label_bars(ax)
ax.set(xlabel=None, ylabel="Parents needed")
fk.save(fig, os.path.join(os.path.dirname(__file__), "bar_comparison.png"))
