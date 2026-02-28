# dotfiles

> Manage your dotfiles setup — install, update, and edit configs.
> More info: <https://github.com/eelko/dotfiles>

- Install/update all dotfiles and tools:

`cd ~/.dotfiles && ./install.sh`

- Quick update (pull + install):

`dotfiles-update`

- Open dotfiles directory:

`dotfiles`

- Edit a config directly:

`zshrc`

- Add machine-specific overrides (not tracked by git):

`$EDITOR ~/.zshrc.local`

- Available local override files:

`~/.zshrc.local, ~/.bashrc.local, ~/.gitconfig.local, ~/.tmux.conf.local, ~/.ssh/config.d/local`
