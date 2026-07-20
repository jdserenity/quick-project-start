# quick-proj CLI

Versioned source for the global `quick-proj` command.

## Why this setup

- Keep this in a GitHub repo.
- Run `./install.sh` after each pull — it syncs templates so new projects get the latest policy.
- The installer copies `quick-proj` into `~/.local/bin/quick-proj`.
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

`install.sh` refreshes the binary, bundled scaffold agent files, and all files under `~/.config/quick-proj/templates/` from this repo (including `sz.py`). Upgrading from `new-proj` migrates `~/.config/new-proj`, removes `~/.local/bin/new-proj`, and updates shell integration in `~/.zshrc` when present.

## Usage

```bash
quick-proj "my-project"              # creates project; cd into it (with shell integration)
quick-proj --no-repo "my-project"    # files only; skip git init and GitHub; still cds
cd /path/to/existing-project
quick-proj --existing                # add scaffold/ here; git + GitHub unless --no-repo; no cd
quick-proj --existing --no-repo      # scaffold only; skip git/GitHub
cd /path/to/existing-project
quick-proj --update                  # refresh scaffold agent files and add missing scaffold files; no deletions
quick-proj --agent-version           # show this project's scaffold version vs latest (exit 1 if behind)
```

`./install.sh` adds shell integration to `~/.zshrc` (once). Run `source ~/.zshrc` or open a new terminal so `quick-proj` can change directory in your shell.

Without integration loaded, the command only prints a `cd` line; run `eval "$(quick-proj "my-project" 2>/dev/null)"` instead.

Creates:

- `~/Documents/coding-temp/my-project/`
- By default: git repository initialized with an `init` commit on `main`, and a public GitHub repo (same name as the project) via `gh`, with initial push
- root `AGENTS.md` (pointer to scaffold/), `README.md`, `.gitignore`, and `scripts/` (e.g. `scripts/sz.py`)
- scaffold folder (default `scaffold`) with:
  - `AGENT-COMMS.md` — how agents talk to you
  - `AGENT-WORKFLOW.md` — how agents work (includes `scaffold version: X.Y.Z`)
  - `ARCH-HUMAN.md` — architecture for humans
  - `ARCH-LLM.md` — architecture for agents
  - `PROJECT-KNOWLEDGE.md` — hard-won lessons
  - `skills/` (empty folder)

Requires `git` and [GitHub CLI](https://cli.github.com/) (`gh`) logged in (`gh auth login`). If either is missing or `gh repo create` fails, the local project is still created and you get a warning.

## Configure defaults

Global runtime config:

- `~/.config/quick-proj/config.env`
  - `SCAFFOLD_DIR_NAME="scaffold"`
  - optional: `BASE_DIR="/some/path"`
  - optional: `TEMPLATES_DIR="/some/path"`
  - optional: `SCRIPTS_DIR="/some/path"`

Global templates (refreshed on every `./install.sh`):

- `~/.config/quick-proj/templates/`
  - `AGENT-COMMS.md`, `AGENT-WORKFLOW.md`
  - `ARCH-HUMAN.md`, `ARCH-LLM.md`, `PROJECT-KNOWLEDGE.md`
  - `AGENTS.md` (root pointer to scaffold/)
  - `README.md`
  - `.gitignore`
  - `sz.py` (copied into project root `scripts/` when scaffolding)

Per-run overrides:

- `QUICK_PROJ_BASE_DIR="/some/path" quick-proj "my-project"`
- `QUICK_PROJ_SCAFFOLD_DIR_NAME="blueprint" quick-proj "my-project"`
- `QUICK_PROJ_TEMPLATES_DIR="/some/path" quick-proj "my-project"`

Legacy `NEW_PROJ_*` environment variable names still work.

## Tests

```bash
./tests/run-tests.sh
```
