# 🏠 Dotfiles

Personal configuration files for macOS and Linux systems.

Managed with symlinks — one repo, all machines in sync.

## What's Included

| Config | Path | Description |
|--------|------|-------------|
| Alacritty | `~/.config/alacritty/` | Terminal emulator (macOS only) |
| Zsh | `~/.zshrc` | Zsh shell configuration |
| Bash | `~/.bashrc`, `~/.bash_profile` | Bash shell configuration |
| SSH | `~/.ssh/config` | SSH hosts and settings |
| Git | `~/.gitconfig` | Git identity and preferences |

## Quick Start

```bash
# Clone the repo
git clone git@github.com:YOUR_USERNAME/dotfiles.git ~/.dotfiles

# Run the installer
cd ~/.dotfiles
chmod +x install.sh
./install.sh
```

The installer will:
1. Detect your OS (macOS or Linux)
2. Back up any existing configs to `~/.dotfiles-backup/`
3. Create symlinks from the repo to the expected locations
4. Install only what's relevant for the current system

## Per-Machine Overrides

Drop local overrides (that you don't want in git) in:
- `~/.zshrc.local` — sourced at end of `.zshrc`
- `~/.bashrc.local` — sourced at end of `.bashrc`
- `~/.ssh/config.d/local` — included by main SSH config
- `~/.gitconfig.local` — included by main `.gitconfig`

These files are gitignored so they stay on the machine where you create them.

## SSH Config

The SSH config uses `Include` to load all files from `~/.ssh/config.d/`.
Add host entries per machine or per project in that directory:

```
~/.ssh/config.d/
├── 00-defaults       ← from this repo (global defaults)
├── homelab           ← from this repo (your servers)
└── local             ← machine-specific (gitignored)
```

## Updating

```bash
cd ~/.dotfiles
git pull
./install.sh   # re-run to pick up any new files
```

## Uninstall

```bash
cd ~/.dotfiles
./uninstall.sh
```

This removes all symlinks and restores your backups.
