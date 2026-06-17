# new-proj CLI

Versioned source for the global `new-proj` command.

## Why this setup

- Keep this in a GitHub repo.
- Run `./install.sh` after each pull.
- The installer copies `new-proj` into `~/.local/bin/new-proj`.
- You can delete this clone anytime; installed command keeps working.

## Install / update

```bash
./install.sh
```

Recommended update flow:

```bash
git pull
./install.sh
```

## Usage

```bash
new-proj "my-project"              # creates project; cd into it (with shell integration)
new-proj --no-repo "my-project"    # files only; skip git init and GitHub; still cds
cd /path/to/existing-project
new-proj --existing                # add AGENTS.md + docs/ here; git + GitHub unless --no-repo; no cd
new-proj --existing --no-repo      # scaffold only; skip git/GitHub
cd /path/to/existing-project
new-proj --agent-upgrade           # replace project-root AGENTS.md with newest template; no other changes
```

`./install.sh` adds shell integration to `~/.zshrc` (once). Run `source ~/.zshrc` or open a new terminal so `new-proj` can change directory in your shell.

Without integration loaded, the command only prints a `cd` line; run `eval "$(new-proj "my-project" 2>/dev/null)"` instead.

Creates:

- `~/Documents/coding-temp/my-project/`
- By default: git repository initialized with an `init` commit on `main`, and a public GitHub repo (same name as the project) via `gh`, with initial push
- root `AGENTS.md`, `README.md`, and `.gitignore`
- scaffold folder (default `docs`) with:
  - `ARCHITECTURE.md`
  - `DEPLOY.md`
  - `TODO.md`

Requires `git` and [GitHub CLI](https://cli.github.com/) (`gh`) logged in (`gh auth login`). If either is missing or `gh repo create` fails, the local project is still created and you get a warning.

## Configure defaults

Global runtime config:

- `~/.config/new-proj/config.env`
  - `SCAFFOLD_DIR_NAME="docs"`
  - optional: `BASE_DIR="/some/path"`
  - optional: `TEMPLATES_DIR="/some/path"`

Global templates:

- `~/.config/new-proj/templates/`
  - `AGENTS.md`
  - `ARCHITECTURE.md`
  - `README.md`
  - `DEPLOY.md`
  - `TODO.md`
  - `.gitignore`

Per-run overrides:

- `NEW_PROJ_BASE_DIR="/some/path" new-proj "my-project"`
- `NEW_PROJ_SCAFFOLD_DIR_NAME="blueprint" new-proj "my-project"`
- `NEW_PROJ_TEMPLATES_DIR="/some/path" new-proj "my-project"`

## Tests

```bash
./tests/run-tests.sh
```
