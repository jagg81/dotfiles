# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles for macOS. Managed via a bootstrap script that symlinks or copies config files into `$HOME`.

## Bootstrap

```sh
script/bootstrap
```

Interactive — prompts per section (Bash, Vim, SSH, tmux, Git, VS Code, Cursor, Claude Code). Each section can be accepted or skipped. Prints a summary of what was linked, copied, backed up, or skipped.

## File naming conventions

| Suffix | Behaviour in bootstrap |
|--------|----------------------|
| `.symlink` | Symlinked to `$HOME` via `link_config` |
| `.copylink` | Copied to `$HOME` via `copy_config` (used for paths that don't support symlinks, e.g. `~/Library/Application Support/`) |

Files without these suffixes are not processed by bootstrap.

## Adding a new tool

1. Create a directory for the tool (e.g. `newtool/`)
2. Add config files with `.symlink` or `.copylink` suffix
3. Add the corresponding `link_config` or `copy_config` call in `script/bootstrap` under a new `if confirm "..."` block

## Structure

- `bash/` — `.bash_profile`, `.bashrc`, `.bash_aliases`, `.localrc` template
- `vim/` — `.vimrc`, `.vim/` directory with Pathogen plugins in `bundle/` and native pack plugins in `pack/`
- `git/` — `.gitconfig` template (fill in `[user]` section per machine)
- `claude/` — Claude Code global config: `CLAUDE.md`, `settings.json`, `statusline.sh`, agents, skills
- `vscode/`, `cursor/` — Editor settings (copied, not symlinked) and `extensions.txt` listing installed extensions
- `ssh/` — SSH config and rc
- `tmux/` — tmux config
- `bin/` — Utility scripts (only `delete-merged-branches.sh` is currently symlinked to `~/bin/`)

## Vim plugins

Two plugin systems coexist:
- **Pathogen** (`vim/vim.symlink/bundle/`) — legacy plugins managed as git submodules
- **Native pack** (`vim/vim.symlink/pack/`) — Vim 8 native packages (e.g. `copilot.vim`), auto-loaded at startup

## Sensitive config

Machine-specific or sensitive values (API tokens, etc.) go in `~/.localrc` (copied from `bash/localrc.copylink`, never committed). The `.env.local` file at repo root is gitignored for the same purpose.
