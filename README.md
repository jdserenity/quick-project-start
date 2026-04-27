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
new-proj "my-project"
```

Creates:

- `~/Documents/coding-temp/my-project/`
- Git repository initialized
- scaffold folder (default `docs`)
- files inside scaffold folder:
  - `AGENT.md`
  - `ARCHITECTURE.md`
  - `README.md`
  - `DEPLOY.md`
  - `TODO.md`
- root `.gitignore`

## Configure defaults

Global runtime config:

- `~/.config/new-proj/config.env`
  - `SCAFFOLD_DIR_NAME="docs"`
  - optional: `BASE_DIR="/some/path"`
  - optional: `TEMPLATES_DIR="/some/path"`

Global templates:

- `~/.config/new-proj/templates/`
  - `AGENT.md`
  - `ARCHITECTURE.md`
  - `README.md`
  - `DEPLOY.md`
  - `TODO.md`
  - `.gitignore`

Per-run overrides:

- `NEW_PROJ_BASE_DIR="/some/path" new-proj "my-project"`
- `NEW_PROJ_SCAFFOLD_DIR_NAME="blueprint" new-proj "my-project"`
- `NEW_PROJ_TEMPLATES_DIR="/some/path" new-proj "my-project"`
