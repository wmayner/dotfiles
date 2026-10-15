---
name: figures
description: Use before making any figure a person will read, such as a matplotlib or seaborn plot, a chart in a report or slide, or a diagram of a method or pipeline, and when designing the figures in an experiment spec. It covers choosing what to show, keeping text out of the image, a matplotlib house style with direct labels and a check that runs on save, and HTML routes for interactive figures on a page and for diagrams, each with a PNG for slides. Not for dashboards (use dataviz).
---

# Figures

The goal is a figure that a busy researcher understands in five seconds, made in one pass.

Figures go wrong in two ways. They try to show every result, so the figure becomes a table drawn as a plot. And they put the caption's job into the image: definitions, statistics, verdicts, and titles written as sentences. Writing "one idea per figure" doesn't prevent this, because the idea becomes the title and everything is still drawn below it. Reviewing a figure by asking "is every term defined?" makes labels longer. The question to ask is "what can I remove?"

## 1. Decide before drawing

Write this block in your notes, or in the spec when figures are designed there. It takes two minutes and replaces most revision rounds.

```
Claim:    the one sentence the figure argues
Template: bar | line | scaling | calibration | diverging line | Pareto | scatter | heatmap
Shows:    the one comparison the claim needs (which series, which subset); the rest goes to a table
Accent:   the one element the eye should land on (ACCENT colour; everything else grey)
Text:     every string that will appear in the image, listed, at most about 25 words outside tick labels
Caption:  at most 3 sentences under the image: what is plotted, how it was measured, n, what the error bars are
Sketch:   a 4-line ASCII sketch
```

At the spec stage, the person approves this block, not a prose description of encodings ("rows: methods × targets; filled vs open markers; verdict in the margin" reads as simple and draws as a wall). Better still, draw the figure once from fake data and show the image.

## 2. Choose what to show

- One panel by default. Use small multiples (at most 4 panels, shared axes) only when the same comparison repeats across conditions.
- At most 4 series per panel. Keep the ones the claim needs; grey or drop the rest.
- If you want a verdict column, a statistic printed on every row, "two versions", or a panel per target, you are drawing a table. Put the table on the page and draw the one row that matters.
- Diagnostics and secondary results do not go in the figures someone is asked to read.

## 3. Keep text out of the image

| Content | In the image? | Where instead |
|---|---|---|
| The claim | No sentence titles, no suptitle | the heading or slide title above the figure, or the caption's first sentence |
| Definitions, n, interval method, thresholds, priors, Bayes factors, sampling notes | No | caption or page text |
| Axis labels | Yes, at most about 6 words, with units | |
| Series names | Yes, next to the data (`fk.label_lines`, `fk.label_bars`) | a legend only for 5+ categories, and then you have too many |
| One key number | Yes, if it is the point: one, next to its mark | |
| Panel names | Yes, at most 4 words | |

There are no annotation boxes, no paragraphs, no rotated tick labels, no variable names from the code, and no numbers to four decimals. Rigor belongs in the caption. The image carries only what the eye needs.

## 4. Draw

Choose the medium first:
- A figure that will sit on an HTML page (a results page or an artifact): use HTML, as described in section 8.
- A figure for a paper, or a quick look during analysis: use matplotlib, as below.
- A diagram of a method: use HTML, as described in section 7.

Write one standalone script per figure, about 100 lines or fewer. It reads saved tidy data (CSV or parquet) and does nothing else. Don't draw inside the analysis script: helpers built to take any number of rows let rows pile up.

```python
import os, sys
sys.path.insert(0, os.path.expanduser("~/.claude/skills/figures"))
import figkit as fk          # for code that must run elsewhere, copy figkit.py next to the script

fk.use()                     # house style and the Inter font; call after any sns.set_theme, or instead of it
fig, ax = plt.subplots()     # 7 x 4 in default; don't enlarge to fit more, since text shrinks when the image is scaled
ax.plot(k, err_cond, color=fk.ACCENT, label="conditioned")
ax.plot(k, err_grad, color=fk.GREY, label="best gradient")
ax.set(xscale="log", xlabel="Units kept", ylabel="Error left in the target")
fk.plain_ticks(ax.xaxis)     # 1, 10, 100 rather than powers of ten
fk.label_lines(ax)           # names at line ends; fk.label_bars(ax) for bar charts
fk.save(fig, "results/figures/fig1.png")   # prints FIGURE CHECK with anything to fix
```

- Colours: `fk.ACCENT` for the claim, `fk.GREY` or `fk.LIGHT` for context, `fk.BLUE` for a second highlighted series, and `fk.CATEGORICAL` only when the categories themselves are the point. Keep each colour's meaning fixed across a set of figures.
- With seaborn, pass `saturation=1` to bar plots and `palette={level: colour}` so the accent stays exact.
- Log axes need `fk.plain_ticks`. Draw the reference line (chance, threshold, y = x) thin and grey, and explain it in the caption.
- Worked examples, with code and the rendered PNG, are in `~/.claude/skills/figures/examples/`. View one if you're unsure what the target looks like.

## 5. Check it once (cheap; do it every time)

1. `fk.save` prints `FIGURE CHECK`. Fix every item, or say in one line why it's deliberate.
2. Read the PNG once and answer, one line each:
   - Without the caption, what does the figure say? Is that the Claim?
   - What can you remove (text, series, panels, legend, gridlines) without losing the claim? Remove it.
   - Is anything hard to read: small, overlapping, or two colours that look alike?
3. Fix and save again. Stop there; a second look is needed only if the first changed the structure.

## 6. A fresh critic (only for figures going to a mentor, a deck or a paper)

Spawn one subagent that has none of your context. Give it only the PNG path and the Claim, with the prompt in `~/.claude/skills/figures/critic.md`. Apply its cuts, and do one round only. Use this sparingly: it costs a subagent, and step 5 catches most problems.

## 7. Diagrams of a method, pipeline or setup

Don't draw these in matplotlib. Write HTML that links `diagram.css` (cards, pills, numbered steps, chevrons, accent and muted colours, Inter), and render it to a PNG:

```
sh ~/.claude/skills/figures/render_html.sh diagram.html diagram.png 1600 500   # width and height of .canvas
```

The same rules apply, in this form:
- Each box gets a bold name of at most 5 words and one grey line of at most 12 words.
- No legend.
- One accent colour for the thing the diagram is about.
- Red only for ablated or failed, green only for passed.
- One concrete running example (a real token or a real unit) that appears in every panel.
- The same symbol always means the same thing.
- A wide canvas, 2:1 to 3:1.

See `examples/diagram.html`.

## 8. Figures for a page: HTML, with a PNG rendered from the same file

When a figure will live on an HTML page, draw it in HTML and SVG rather than matplotlib, for two reasons. First, Claude's design judgment is much better in HTML and CSS. Second, a page can show details on demand. The static view stays clean, and the exact values, intervals, n, verdicts and identifiers appear on hover or click. That takes away the pull to print statistics in the image.

- Start from `examples/interactive_dots.html`. It has colour tokens for light and dark mode, the Inter font, D3 from a CDN, the data inline as JSON, and a tooltip. Have your Python script write the data JSON into a copy of the file, and adapt `draw()`.
- The static view obeys sections 2 and 3. The tooltip, or a panel that opens on click, carries everything else.
- Render the PNG for slides from the same file: `sh ~/.claude/skills/figures/render_html.sh figure.html figure.png 900 420`, where 900 and 420 are the size of the `.fig` box. Look at the PNG once, as in step 5. `fk.save`'s check doesn't run here, so apply its limits by eye.
