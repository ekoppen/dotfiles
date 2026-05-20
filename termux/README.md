# Termux

Termux config for Android — currently tuned for a Galaxy Fold with an
Avatto BT-keyboard, but the defaults are sensible for any physical
keyboard setup.

## Quick start on a fresh Termux install

1. **Bootstrap packages:**
   ```sh
   pkg update && pkg upgrade
   pkg install git openssh
   ```

2. **Clone the dotfiles:**
   ```sh
   git clone https://github.com/ekoppen/dotfiles ~/.dotfiles
   ```

3. **Run the installer:**
   ```sh
   cd ~/.dotfiles && ./install.sh
   ```

   The installer detects Termux automatically (via `$TERMUX_VERSION`
   or `uname -o == Android`), skips Alacritty, creates `~/.termux/`,
   symlinks `termux.properties`, and runs `termux-reload-settings`.

4. **Recommended extras:**
   ```sh
   pkg install starship zoxide fzf eza tmux nano termux-api
   termux-setup-storage     # grant access to ~/storage (Pictures, ...)
   ```

   `starship` powers the prompt, `eza` powers the listing aliases,
   and `termux-api` enables the `pbcopy` / `pbpaste` / `open` aliases
   defined in `~/.shell/termux.sh`.

## What's in `termux.properties`

| Setting | Value | Why |
|---|---|---|
| `hide-soft-keyboard-on-startup` | `true` | BT keyboard makes the touch keyboard redundant |
| `back-key` | `escape` | Tap-back doubles as ESC |
| `bell-character` | `ignore` | No beep, no vibration |
| `enforce-char-based-input` | `true` | Avoids dropped chars on Avatto-style BT keyboards |
| `extra-keys` | 2 rows | Modifiers + nav cluster for touch use |
| `terminal-cursor-style` | `block` | Matches the desktop terminal |

## Re-applying changes

After editing `termux.properties` (or pulling new dotfiles):

```sh
termux-reload-settings
```

The installer runs this for you on every `install.sh`.

## Uninstall

```sh
cd ~/.dotfiles && ./uninstall.sh
```

The Termux symlink is removed and the previous file (if any) is
restored from the most recent backup.
