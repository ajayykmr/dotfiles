---
name: dotfiles
description: Change files that chezmoi manages from my dotfiles repo. Use when changing my shell or nvim config, installed packages, app settings, or global assistant config in ~/.claude (CLAUDE.md, settings.json, skills, agents), or when working in the dotfiles repo itself.
---

# Changing dotfiles

My home directory config comes from a public dotfiles repo, applied with chezmoi. The repo is the source of truth: an edit made directly to a file in `~` is overwritten by the next `chezmoi apply`.

## Find the source

- `chezmoi source-path` prints the source directory, `<repo>/home`. The repo's `README.md` (one level up) covers its layout, setup scripts and settings sync; read it before changing anything outside `home/`.
- `chezmoi source-path <target>` prints a file's source, or reports that it isn't managed.
- `chezmoi git -- <args>` runs git at the repo root.

## Change a file

1. Run `chezmoi status <target>`. An `M` in the first column means the live file changed since chezmoi last wrote it; the `/config` and `/plugin` commands change `~/.claude/settings.json` this way. Check `chezmoi diff <target>`, then bring a change worth keeping into the source with `chezmoi re-add <target>` before editing it, or ask me which side wins.
2. Edit the source file. Templates can't be re-added, so always edit them at the source. To start managing a new file, run `chezmoi add <target>`.
3. Preview with `chezmoi diff <target>`. A directory target needs `-r`; without it the diff shows nothing.
4. Apply only what you changed: `chezmoi apply <target>`. Ask before a bare `chezmoi apply`: it applies every file and also runs any setup scripts that are due (package installs, app settings).

## Gotchas

- An empty source file without the `empty_` prefix makes chezmoi delete its target on apply.
- `chezmoi re-add` also runs the repo's re-add hooks, which save the synced app settings (macOS, KDE) into the repo.
- The repo is public. Keep secrets, work-specific details and anything about other people out of it. Machine-specific or work-only shell config goes in `~/.zshrc.local` or `~/.zshenv.local`, which aren't managed.
- `~/.claude.json` is the assistant's own state and holds account details. It isn't managed; print its key names only, never its values.
