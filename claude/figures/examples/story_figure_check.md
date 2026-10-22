# Fresh-reader test of story_figure.png

One new subagent (Opus) with no context was given only the PNG, no caption, and asked: what was done, what was found, and what was unclear or could be read more than one way. 22 October 2026. The content is made up for the template.

Intended reading: copies of a toy network each get a planted rule; on new copies, methods trained on other copies pick out the planted circuit far more often than untrained methods, the mask network does best, and training on 96 copies helps the two small networks more than the linear probe.

## Round 1

Done: "copies of one toy network with 8 layers. Each copy was trained with its own planted rule ... The task is to look at a network's activations and pick out the units of its planted circuit. Three methods that get no training for this task ... are compared with three trained methods ... trained on either 24 or 96 copies and then tested on 12 copies it never saw."

Found: "The trained methods beat the untrained ones, and training on 96 copies beats training on 24. The mask network trained on 96 copies does best, with 98 out of what I take to be 120 test cases."

Unclear, and the change made for each:
- "all 120" did not match 96 + 12, and a test case was not defined. The held-out count now says "10 test inputs each", so 12 × 10 = 120 can be read off.
- Counts or percentages? Settled by the same change and "all 120"; the header now says what is counted ("picked exactly the planted circuit's units"), which also defines "found".
- The zoom's line about training read as training on Network A itself. It now says the mask network was trained on the other copies only and runs once on Network A.
- Network A and B sat beside the grid of 96, so read as part of it. Their tag now reads "new copy", the words used for the 12.
- The zoom did not show the true circuit, so success could not be judged. The planted circuit's units are now marked under the bars, with a check.
- The random-guessing line had no value. It is now labelled "random guessing, 4".
- The linear probe and small network cards looked alike. The small network now has "two layers" under it; the cards stay alike on purpose, since only the method should change.

The reader got the setup and the main finding right on the first reading. The fixes were applied once; there was no second round.
