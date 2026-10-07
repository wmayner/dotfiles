---
name: fresh-reader-review
description: Use when a document, update, explanation, report, slide deck or message was written with project context and will be read by someone who lacks it (a mentor, collaborators, a newcomer, or the author later), and it should be clear, brief and well argued before it is sent. Also use when told to "get a fresh agent to review", "iterate until it's actually good", or when asking an agent to "pretend it has no context" has not worked.
---

# Fresh-reader review

An author with context cannot read without it, and telling an agent to "pretend you have no context" fails because the context is in its window. Instead, start a new agent that has only the draft and what the real reader knows, have it report where the draft fails that reader, revise, and repeat with another new agent.

## Before the first round, write down (the reviewer never sees the third item)

1. **Reader:**
   - who they are
   - what they already know, including names, tools and projects they have seen. Anything left out gets flagged as unknown.
   - what they have said themselves that the draft quotes or answers. Otherwise a correct quotation gets "fixed" as unsupported.
   - which linked material they will open. Reviewers can't follow links.
   - what they don't know
   - how they will read: once, in a few minutes, in a meeting, on a phone
2. **Background files:** only what that reader actually has, such as a paper they wrote. Nothing else. If it is unclear which version of an earlier message the reader saw, ask the user.
3. **Intended message:** two to four sentences the reader should come away with.

## Each round

1. Start new reviewers with the Agent tool: `subagent_type: general-purpose`, `model: opus` unless the user named another. Never `fork` (it inherits this conversation) and never SendMessage a previous reviewer (it remembers the old draft). Round 1: two reviewers in parallel, since each catches different things. Later rounds: one.
2. The prompt is the template below, filled in. It says nothing about the project, the author's intentions or earlier rounds.
3. Triage the report:
   - Compare the restatement with the intended message. A mismatch is the most important problem. After that, findings raised by both reviewers come first.
   - Before acting on any factual claim a reviewer makes (for example, "the paper has no such matrix"), check it yourself against the background files and against the author's own sources. Reviewers report confident absences that are false.
   - If a fix needs a fact you don't have (a number only the author knows), put a marked placeholder such as `[AUTHOR: weight overlap for X?]` in the draft and list it for the user. Don't drop the claim and don't supply a value yourself.
   - Fix places where the reader got lost, terms used before they are defined, overstated claims, and the reader's likely first questions, which the draft should answer.
   - If a flag concerns something the real reader knows, don't change the draft; add it to the reader description for the next round.
4. Revise. For prose, apply `writing-naturally` if it is available.

**Stop** when a fresh reviewer's restatement matches the intended message and it reports nowhere it got lost that the real reader would also hit. Stop after four rounds regardless, and report what is still unresolved.

## Reviewer prompt template

```
You are a first-time reader of a draft. Read it once, as the reader described below, and report honestly where it fails you. You are not an editor or the author's collaborator: don't fill gaps with your own knowledge or guess what the author meant. If you had to guess, that is a finding.

THE READER YOU ARE STANDING IN FOR: {reader description}

WHAT YOU MAY READ: the draft, {path}{, and, only to check claims against it, {background files}}. Open no other files and run no searches.

REPLY WITH THESE PARTS, IN ORDER:
1. Restatement: in five sentences or fewer, what the draft claims and why the reader should believe it, in your own words, written before re-reading anything.
2. Where you got lost: each place you had to reread, guess or couldn't follow. Quote the phrase and say what you needed at that point (what a number is relative to, what a label means, why a step was taken, what evidence backs a claim).
3. Terms used before they are defined, or never defined, that this reader would not know.
4. Claims the draft overstates, or evidence it leaves out that cuts against it (check against the background files if you have them).
5. The first three questions this reader would ask the author.
6. What to cut.
7. Verdict: clarity, brevity, flow and argument, one line each; then the single change that would help this reader most, with a rewrite of the worst passage if that helps.
```

## Common mistakes

| Mistake | Consequence |
|---|---|
| Reusing a reviewer, or forking | It judges the new draft against the old one, or against context the reader lacks |
| Telling the reviewer what the draft is meant to say | It reads that into the draft and finds no gap |
| Leaving out what the reader already knows | False flags (for example, an internal tool name the reader uses every day) |
| Acting on a reviewer's factual claim without checking it | You edit out a correct statement |
| Only asking "is it clear?" | Generic praise; nothing anticipates the reader's actual questions |
