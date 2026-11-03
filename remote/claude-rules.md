## On the MATS cluster
- There is no clipboard, no `op` CLI and no 1Password agent. For text to copy, give me the temp file's full path, or `sh <path>` for a script I should run.
- Keys live in files under `~/.config` that only I can read. Never copy a key into a repo, a notebook or a log.
- Git commit signing is not set up here.
- Repository clones, virtual environments, model downloads and other large scratch go under `/ephemeral/$USER` (local, wiped on reboot), never in `/tmp` or a scratchpad left in `/tmp`: `/tmp` shares the machine's small root disk with every user, and on 20 October 2026 the compute admin found it at 97%, 42 GB of it torch environments in one Claude scratchpad. Sessions start with `CLAUDE_CODE_TMPDIR=/ephemeral/$USER/claude-tmp` (zshrc, agents-up, and the tmux server's environment), which puts scratchpads there.
- The better-figures repository (the `better-figures:figures` skill) is cloned at `/mnt/nw/home/w.mayner/better-figures`. Change the skill there.
- Reference figures that can't go in a public repository are in `/mnt/nw/home/w.mayner/figure-references`: a collaborator's unpublished figures in `sauers/`, and the summary figure papers' Figure 1s, cropped, in `figure1/`. Each folder's README says what is there. Look at the relevant ones before drawing a summary or story figure, and never copy them into a repository.
