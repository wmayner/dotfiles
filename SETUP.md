# Modern Tools Setup Guide

This guide covers setup for the modern CLI tools added in 2026.

## Git Delta (Beautiful Diffs)

**Already configured** in `git/gitconfig.symlink`:
- Set as default pager for git
- Side-by-side view disabled (use `--side-by-side` flag to enable)
- Line numbers enabled
- Navigation with `n` and `N` between diff sections

**Usage:**
```bash
git diff              # Uses delta automatically
git log -p            # Uses delta for commit diffs
git show <commit>     # Uses delta
```

**Tips:**
- Press `n` / `N` to jump between diff sections
- Use `git diff --side-by-side` for side-by-side view
- Configure theme in `git/gitconfig.symlink` [delta] section

## Modern CLI Tool Aliases

**Already configured** in `zsh/zshrc.symlink` (if tools are installed):

### bat (cat replacement)
```bash
cat file.txt          # Uses bat with syntax highlighting
catp file.txt         # Plain cat without decorations
```

**Config**: Uses Catppuccin Mocha theme (set via `$BAT_THEME`)

### eza (ls replacement)
```bash
ls                    # Modern ls with colors and icons
l                     # Long listing with git status
ll                    # Long listing
tree                  # Tree view (replaces old tree command)
```

**Features**: Includes git status, file icons, better colors

### fd (find replacement)
```bash
find pattern          # Uses fd (faster, better UX)
fd pattern            # Same as above
```

**Benefits**: Respects .gitignore, faster, simpler syntax

### dust (du replacement)
```bash
du                    # Visual disk usage tree
dust /path            # Analyze disk usage
```

**Features**: Tree view, color-coded sizes

## Python Tools (Manual Setup Required)

### Install via pipx (recommended)
```bash
pipx install ruff
pipx install uv
```

### Or via pip
```bash
pip install -r python/requirements.txt
```

### Ruff (Linter + Formatter)

**Already configured in:**
- `vim/vimrc.symlink` - ALE and neoformat
- `vscode/settings.json` - Default Python formatter
- `vscode/extensions.txt` - Extension to install

**Usage:**
```bash
ruff check .          # Lint current directory
ruff check --fix .    # Fix auto-fixable issues
ruff format .         # Format code
```

**VSCode**: Auto-formats on save, organizes imports

**Vim**: Use `:ALEFix` or leader+f to format

### uv (Fast pip replacement)

**Usage:**
```bash
# Instead of: pip install package
uv pip install package

# Create virtual environment
uv venv

# Install from requirements.txt
uv pip install -r requirements.txt
```

**Benefits**: 10-100x faster than pip

## Lazygit (Git TUI)

**No config needed** - works out of the box.

**Usage:**
```bash
lazygit               # Open in current repo
```

**Keybindings** (in lazygit):
- `?` - Show help
- `1-5` - Switch panels (Status, Files, Branches, Commits, Stash)
- `a` - Stage/unstage all
- `space` - Stage/unstage file
- `c` - Commit
- `P` - Push
- `p` - Pull

## Verification Commands

After installing, verify everything works:

```bash
# Check installations
bat --version
eza --version
fd --version
dust --version
delta --version
lazygit --version
ruff --version
uv --version

# Test git delta
git log -p -1

# Test aliases
cat README.md         # Should use bat
ls                    # Should use eza
find . -name "*.py"   # Should use fd

# Test Python tools
ruff check .
uv pip list
```

## Optional: bat Configuration

Create `~/.config/bat/config` for custom settings:

```bash
# Theme
--theme="Catppuccin Mocha"

# Show line numbers and git changes
--style="numbers,changes,header"

# Use italic text
--italic-text=always

# Map files
--map-syntax "*.conf:INI"
--map-syntax ".ignore:Git Ignore"
```

## Optional: lazygit Configuration

Create `~/.config/lazygit/config.yml` for custom settings:

```yaml
gui:
  theme:
    lightTheme: false
    activeBorderColor:
      - cyan
      - bold
    inactiveBorderColor:
      - white
git:
  paging:
    colorArg: always
    pager: delta --dark --paging=never
```

## Troubleshooting

### Delta not showing colors
- Check `$TERM` supports colors: `echo $TERM`
- Should be `xterm-256color` or `tmux-256color`

### eza icons not showing
- Install a Nerd Font (e.g., `brew tap homebrew/cask-fonts && brew install --cask font-hack-nerd-font`)
- Configure terminal to use the Nerd Font

### Ruff not found in VSCode
- Install extension: `charliermarsh.ruff`
- Check Python interpreter is set
- Restart VSCode

### Aliases not working
- Source zshrc: `source ~/.zshrc`
- Or restart terminal
