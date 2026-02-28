# my-tools

> Overview of all modern CLI tools in your dotfiles setup.
> All installed via Brewfile. Run `brew bundle` to install everything.

- Fuzzy find anything (Ctrl+R history, Ctrl+T files, Alt+C dirs):

`fzf`

- Smart cd that learns your habits:

`z {{partial-dirname}}`

- Fast file search (respects .gitignore):

`fd {{pattern}}`

- Fast content search in files:

`rg {{pattern}}`

- Cat with syntax highlighting:

`bat {{file}}`

- Modern ls with icons and git info:

`eza -la --icons --git`

- Short help for any command:

`tldr {{command}}`

- Syntax-highlighted git diffs (automatic via gitconfig):

`git diff`
