# Dotfiles

Personal dotfiles for macOS and Linux — managed with symlinks, one repo for all machines.

## Quick Start

```bash
git clone git@github.com:ekoppen/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./install.sh
```

Or as a one-liner:

```bash
bash <(curl -sL https://raw.githubusercontent.com/ekoppen/dotfiles/main/install.sh)
```

## Profiles

The installer asks which profile to use:

| | Workstation | Server |
|---|---|---|
| Shell (zsh + bash) | ✔ | ✔ |
| Git, SSH configs | ✔ | ✔ |
| Starship prompt | ✔ | ✔ |
| tmux + plugins | ✔ | ✔ |
| CLI tools (fzf, ripgrep, bat, fd, eza, zoxide, delta, tldr) | ✔ | ✔ |
| Nerd Font (JetBrainsMono) | ✔ | ✔ |
| Zsh plugins (autosuggestions, syntax-highlighting) | ✔ | ✔ |
| Terminal emulator (Ghostty / iTerm2 / Alacritty) | ✔ | — |
| xbar (Mac-Mux tmux menu) | ✔ (macOS) | — |
| Homebrew | ✔ | — |
| Nano config | — | ✔ (Linux) |

## OS Support

| OS | Status | Notes |
|---|---|---|
| macOS (Apple Silicon) | Primary | Homebrew + Brewfile |
| Ubuntu / Debian | Supported | apt fallback |
| Fedora | Supported | dnf fallback |
| Other Linux | Partial | Manual package install may be needed |

## Structure

```
~/.dotfiles/
├── install.sh          # Main installer (interactive)
├── update.sh           # Pull + re-link + upgrade
├── uninstall.sh        # Remove symlinks, restore backups
├── Brewfile            # Homebrew packages (macOS)
├── zsh/
│   ├── .zshrc          # Zsh configuration
│   ├── .zshenv         # Environment vars (all zsh instances)
│   └── .zprofile       # Login shell setup (PATH, Homebrew)
├── shell/
│   ├── bashrc          # Bash configuration
│   ├── bash_profile    # Login shell → sources bashrc
│   ├── aliases         # Shared aliases (zsh + bash)
│   └── functions       # Shared functions (zsh + bash)
├── git/
│   ├── .gitconfig      # Git settings + delta + aliases
│   └── .gitignore_global
├── ssh/
│   ├── config          # SSH config (includes config.d/*)
│   └── config.d/
│       ├── 00-defaults # Global SSH defaults
│       └── homelab     # Homelab servers
├── tmux/
│   ├── .tmux.conf      # tmux config (Catppuccin, TPM, vi-keys)
│   └── mac-mux.10s.sh  # xbar plugin for tmux menu bar
├── config/
│   ├── starship.toml   # Starship prompt (Catppuccin Mocha)
│   ├── alacritty/      # Alacritty terminal (macOS + Linux)
│   ├── ghostty/        # Ghostty terminal
│   └── nvim/           # Neovim (placeholder)
├── nano/               # Nano config (Linux servers)
├── claude/             # Claude Code settings
└── tldr/               # Custom tldr pages
```

## Updating

```bash
cd ~/.dotfiles && ./update.sh
```

This will:
1. Pull latest changes from git
2. Re-run symlinks (non-interactive)
3. Upgrade Homebrew packages (if available)
4. Update tmux plugins and tldr cache

Or use the alias: `dotfiles-update`

## Non-Interactive Mode

For automation or CI, set `DOTFILES_UPDATE=1`:

```bash
DOTFILES_UPDATE=1 ./install.sh
```

You can also preset choices via environment variables:

```bash
DOTFILES_PROFILE=server DOTFILES_UPDATE=1 ./install.sh
DOTFILES_PROFILE=workstation DOTFILES_TERMINAL=ghostty DOTFILES_UPDATE=1 ./install.sh
```

## Per-Machine Overrides

These files are created automatically and ignored by git:

| File | Purpose |
|---|---|
| `~/.zshrc.local` | Machine-specific zsh config |
| `~/.bashrc.local` | Machine-specific bash config |
| `~/.gitconfig.local` | Git name/email, machine-specific settings |
| `~/.tmux.conf.local` | Machine-specific tmux config |
| `~/.ssh/config.d/local` | Machine-specific SSH hosts |

## Theme

Everything uses **Catppuccin Mocha** — terminal, tmux, git delta, fzf, starship.

## Uninstall

```bash
cd ~/.dotfiles && ./uninstall.sh
```

Removes all symlinks and restores the most recent backup.
