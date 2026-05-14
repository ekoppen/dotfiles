# ╔══════════════════════════════════════════════════════════════════╗
# ║  .zshrc  ·  Managed by dotfiles                                ║
# ╚══════════════════════════════════════════════════════════════════╝

# ─── History ──────────────────────────────────────────────────────

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY          # Share history across sessions
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicate entries first
setopt HIST_IGNORE_DUPS       # Don't record duplicates
setopt HIST_IGNORE_SPACE      # Don't record commands starting with space
setopt HIST_VERIFY            # Show command before executing from history
setopt APPEND_HISTORY         # Append to history file
setopt INC_APPEND_HISTORY     # Write immediately, not at shell exit

# ─── General Options ─────────────────────────────────────────────

setopt AUTO_CD                # cd by typing directory name
setopt AUTO_PUSHD             # Push directory onto stack with cd
setopt PUSHD_IGNORE_DUPS      # Don't push duplicates
setopt CORRECT                # Suggest corrections for typos
setopt INTERACTIVE_COMMENTS   # Allow comments in interactive shell
setopt NO_BEEP                # Silence

# ─── Completion ───────────────────────────────────────────────────

autoload -Uz compinit
compinit

zstyle ':completion:*' menu select                      # Arrow key menu
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'    # Case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # Colorized completion
zstyle ':completion:*:descriptions' format '%F{yellow}── %d ──%f'
zstyle ':completion:*:warnings' format '%F{red}No matches%f'

# ─── Key Bindings ─────────────────────────────────────────────────

bindkey -e                    # Emacs-style bindings (Ctrl+A/E etc.)
bindkey '^[[A' history-search-backward   # Up arrow: search history
bindkey '^[[B' history-search-forward    # Down arrow: search history
bindkey '^[[3~' delete-char              # Delete key
bindkey '^[[H' beginning-of-line         # Home key
bindkey '^[[F' end-of-line               # End key

# ─── Path ─────────────────────────────────────────────────────────

# Homebrew (macOS)
if [[ -d "/opt/homebrew/bin" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Local bins
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/bin" ]]        && export PATH="$HOME/bin:$PATH"

# ─── Auto-tmux in Alacritty ──────────────────────────────────────
#
# Alacritty has no native tabs by design — tmux provides them plus a
# persistent top status bar. Attach to the most recent session, or
# create one if none exist.
#
# Escape hatch: ALACRITTY_NO_TMUX=1 alacritty   → opens plain shell.
#
if [[ -n "$ALACRITTY_WINDOW_ID" && -z "$TMUX" && -z "$ALACRITTY_NO_TMUX" ]] \
    && command -v tmux >/dev/null 2>&1; then
    # If "main" already has a client attached, spawn a fresh unnamed session
    # so a second Alacritty window doesn't mirror the first. Otherwise attach
    # to (or create) "main".
    if tmux has-session -t main 2>/dev/null \
       && [[ -n "$(tmux list-clients -t main 2>/dev/null)" ]]; then
        exec tmux new-session
    else
        exec tmux new -A -s main
    fi
fi

# ─── Environment ──────────────────────────────────────────────────

export EDITOR="${EDITOR:-nano}"
export VISUAL="$EDITOR"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# ─── Shared Aliases & Functions ───────────────────────────────────

[[ -f "$HOME/.aliases" ]]   && source "$HOME/.aliases"
[[ -f "$HOME/.functions" ]] && source "$HOME/.functions"

# ─── Prompt ───────────────────────────────────────────────────────

# If Starship is installed, use it. Otherwise use a simple custom prompt.
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
else
    # Simple but informative prompt: user@host:path (git branch)
    autoload -Uz vcs_info
    precmd() { vcs_info }
    zstyle ':vcs_info:git:*' formats ' %F{magenta}(%b)%f'
    setopt PROMPT_SUBST

    # SSH indicator — show [SSH] in red when connected remotely
    if [[ -n "${SSH_CONNECTION:-}" ]]; then
        _ssh_tag='%F{red}%B[SSH]%b%f '
    else
        _ssh_tag=''
    fi

    # OS icon (requires Nerd Font in terminal)
    case "$(uname -s)" in
        Darwin) _os_icon=$'\uf179 ' ;;
        Linux)  _os_icon=$'\uf17c ' ;;
        *)      _os_icon='' ;;
    esac

    PROMPT='${_ssh_tag}${_os_icon}%F{green}%n@%m%f:%F{blue}%~%f${vcs_info_msg_0_} %F{yellow}%#%f '
fi

# ─── Tool Integrations ───────────────────────────────────────────

# fzf (fuzzy finder)
if command -v fzf &>/dev/null; then
    # Catppuccin Mocha colors (matches tmux/Ghostty theme)
    export FZF_DEFAULT_OPTS=" \
        --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
        --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
        --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
        --color=selected-bg:#45475a \
        --height=40% --layout=reverse --border=rounded --margin=0,1"

    # Use fd for faster file finding (respects .gitignore)
    if command -v fd &>/dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    elif command -v fdfind &>/dev/null; then
        export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fdfind --type d --hidden --follow --exclude .git'
    fi

    # File preview with bat (Ctrl+T)
    if command -v bat &>/dev/null; then
        export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:300 {}'"
    elif command -v batcat &>/dev/null; then
        export FZF_CTRL_T_OPTS="--preview 'batcat --color=always --style=numbers --line-range=:300 {}'"
    fi

    # Directory preview (Alt+C)
    if command -v eza &>/dev/null; then
        export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons --color=always {}'"
    else
        export FZF_ALT_C_OPTS="--preview 'ls -la --color=always {}'"
    fi

    # History search with preview (Ctrl+R)
    export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window=up:3:wrap"

    source <(fzf --zsh) 2>/dev/null || true
fi

# zoxide (smart cd)
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi

# ─── Zsh Plugins ────────────────────────────────────────────────

# zsh-autosuggestions (fish-like suggestions from history)
for _f in \
    /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
    "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"; do
    if [[ -f "$_f" ]]; then source "$_f"; break; fi
done
unset _f

# ─── SSH Agent ────────────────────────────────────────────────────

# Auto-start ssh-agent if not running (Linux servers)
if [[ "$(uname -s)" != "Darwin" ]] && [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
    eval "$(ssh-agent -s)" >/dev/null 2>&1
fi

# ─── Local Overrides ─────────────────────────────────────────────

[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# ─── Syntax Highlighting (must be loaded last) ──────────────────

for _f in \
    /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
    /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
    /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
    "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; do
    if [[ -f "$_f" ]]; then source "$_f"; break; fi
done
unset _f

. "$HOME/.local/share/../bin/env"
