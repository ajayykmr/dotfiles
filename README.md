# dotfiles

Managed with [chezmoi](https://www.chezmoi.io/). Works on macOS and Fedora.

## Layout

```
home/                 chezmoi source (maps to ~), see .chezmoiroot
  .chezmoi.toml.tmpl  chezmoi config (points chezmoi at this repo)
  .chezmoiexternal.toml   oh-my-zsh, powerlevel10k, zsh plugins (cloned if missing)
  .chezmoiscripts/    macOS-only: brew bundle, iTerm2 prefs folder, app prefs import
macos/Brewfile        apps and tools this repo depends on (installed by apply)
macos/iterm2/         iTerm2 reads and writes its prefs here directly
macos/prefs/          exported plists (Rectangle, UnnaturalScrollWheels)
scripts/              helpers, e.g. export-macos-prefs.sh
```

Managed: zsh (`.zshrc`, `.zshenv`, `.p10k.zsh`), nvim (LazyVim), Claude Code (`CLAUDE.md`),
iTerm2, Rectangle, UnnaturalScrollWheels.

## Not tracked (per machine)

- `~/.zshrc.local`, `~/.zshenv.local`: work aliases, paths, `KUBECONFIG`, etc.

## New machine

macOS needs [Homebrew](https://brew.sh) first. Fedora needs `zsh`, `git` and the prompt font first,
then set "Cascadia Code NF" as the terminal font:

```
sudo dnf install zsh git cascadia-code-nf-fonts
chsh -s $(which zsh)
```

Clone this repo anywhere (`~/personal/dotfiles` below), then:

```
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
git clone <repo-url> ~/personal/dotfiles
~/.local/bin/chezmoi init --source ~/personal/dotfiles
~/.local/bin/chezmoi diff
~/.local/bin/chezmoi apply
```

After the first apply, open a new shell so `~/.local/bin` is on `PATH`.

## Day to day

```
chezmoi diff
chezmoi apply
chezmoi re-add
chezmoi edit ~/.zshrc
chezmoi cd
```

- `diff`: what `apply` would change in `~`
- `apply`: write the repo state into `~`
- `re-add`: pull edits made directly in `~` back into the repo (non-template files only)
- `edit`: edit the source copy; needed for templates (`.zshrc`)
- `cd`: open a shell in the repo

After changing Rectangle or UnnaturalScrollWheels settings, run `scripts/export-macos-prefs.sh`.
