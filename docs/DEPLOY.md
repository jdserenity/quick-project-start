# Installing and updating new-proj

There is no hosted deployment. Distribution is: clone this repo, run `install.sh`, use the global `new-proj` command.

## Prerequisites

- macOS or Linux with Bash
- `git` (required for project scaffolding)
- [GitHub CLI](https://cli.github.com/) (`gh`) logged in (`gh auth login`) if you want automatic remote repo creation
- `~/.local/bin` on your `PATH` (common on macOS with Homebrew shell setup)

## First-time install

```bash
cd /path/to/quick-project-start
./install.sh
```

This:

1. Copies `new-proj` → `~/.local/bin/new-proj` (mode `0755`)
2. Creates `~/.config/new-proj/config.env` with `SCAFFOLD_DIR_NAME="docs"` if missing
3. Seeds `~/.config/new-proj/templates/` only for files that do not exist yet

Open a new shell or ensure `~/.local/bin` is on `PATH`, then:

```bash
new-proj "my-project"
```

## Update after `git pull`

```bash
cd /path/to/quick-project-start
git pull
./install.sh
```

`install.sh` refreshes `~/.local/bin/new-proj` but does not overwrite existing global templates.

To change what new projects receive, edit files under `~/.config/new-proj/templates/` directly.

## Customize defaults

Edit `~/.config/new-proj/config.env`:

```bash
SCAFFOLD_DIR_NAME="docs"
# BASE_DIR="/some/other/path"
# TEMPLATES_DIR="/some/other/templates"
```

One-off overrides:

```bash
NEW_PROJ_BASE_DIR="/tmp/scratch" new-proj "experiment"
```

## Troubleshooting

| Symptom | Check |
|---------|--------|
| `new-proj: command not found` | `echo $PATH` includes `~/.local/bin`; re-run `./install.sh` or open a new terminal |
| Warning: git not installed | Install Xcode CLT or `git` via Homebrew |
| Warning: gh not authenticated | `gh auth login` |
| Warning: failed to create GitHub repo | Repo name may already exist; local project still created under base dir |
| Empty `AGENTS.md` in new projects | Run `./install.sh` once, or populate `~/.config/new-proj/templates/AGENTS.md` |
