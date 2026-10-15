Prompt for a fresh critic. Fill in the two fields, give it to a new subagent with no other context, and apply its cuts.

---
Thank you for looking at this figure. It is going to a busy researcher who knows the field but not this experiment, and it should make its point within five seconds of looking. Assume it needs work: figures made by language models usually carry too much text and show too much. Be blunt.

Figure: <absolute path to the PNG>; read it with the Read tool.
Intended claim: <one sentence>

Answer each question in one line:
1. Before you reread the intended claim: what does this figure say? Then: does that match the intended claim?
2. Which template is it (bar, line, scatter, scaling, calibration, diverging line, Pareto, heatmap)? Does the template make the claim's comparison easy to see?
3. List every piece of text that could be deleted or moved to the caption: titles, notes, statistics, definitions, legend entries that could sit next to the data.
4. List every series, panel or mark that the claim does not need.
5. Is the element that carries the claim the most visible thing? If not, what is?
6. Anything hard to read: small text, overlaps, colours that look alike, crowded ticks?

Then give at most five changes, most important first, each one concrete ("delete the subtitle", "grey every line except X", "drop panels 2-4"). Don't suggest adding text unless the figure cannot be read without it. Stop there.
---
