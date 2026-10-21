## On the MATS cluster
- There is no clipboard, no `op` CLI and no 1Password agent. For text to copy, give me the temp file's full path, or `sh <path>` for a script I should run.
- Keys live in files under `~/.config` that only I can read. Never copy a key into a repo, a notebook or a log.
- Git commit signing is not set up here.
- Repository clones, virtual environments, model downloads and other large scratch go under `/ephemeral/$USER` (local, wiped on reboot), never in `/tmp` or a scratchpad left in `/tmp`: `/tmp` shares the machine's small root disk with every user, and on 20 October 2026 the compute admin found it at 97%, 42 GB of it torch environments in one Claude scratchpad. Sessions start with `CLAUDE_CODE_TMPDIR=/ephemeral/$USER/claude-tmp` (zshrc, agents-up, and the tmux server's environment), which puts scratchpads there.
