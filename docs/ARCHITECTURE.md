# new-proj architecture

## Product intent

- Bash CLI that scaffolds a new coding project under a configurable base directory (default `~/Documents/coding-temp`).
- Each run scaffolds files from templates. By default it also creates a local git repo, an `init` commit on `main`, and (when `gh` is available and authenticated) a public GitHub repo with an initial push. Pass `--no-repo` to skip all git/GitHub steps.
- Pass `--existing` from inside an existing project directory to copy `AGENTS.md` and scaffold docs into the current folder; by default also runs git/GitHub setup (init if needed, commit scaffold, `gh repo create` named after the directory unless a project name is passed); pass `--no-repo` to skip git/GitHub; does not overwrite an existing root `README.md` or `.gitignore`; does not change the shell cwd.
- Pass `--agent-upgrade` from anywhere inside an existing project to overwrite root `AGENTS.md` with the newest bundled template (`new-proj` checkout `AGENTS.md`, else `~/.config/new-proj/bundled/AGENTS.md` from last `install.sh`, else embedded fallback). Resolves project root via `git rev-parse --show-toplevel`, or by walking up to the nearest parent with `AGENTS.md` when not in a git repo. No scaffold, git, GitHub, or `cd`.
- Pass `--agent-version` from anywhere inside an existing project to print the project's `AGENTS.md` version (last non-empty line, format `AGENTS.md version: N`) and the latest available version from the same template chain as `--agent-upgrade`. Exit 0 when they match, 1 when the project is missing a version, behind, or has no `AGENTS.md`.
- Root `AGENTS.md` ends with `AGENTS.md version: N` on the last line; bump `N` whenever the template changes.
- Normal and `--no-repo` runs print a `cd` command on stdout (status on stderr). `install.sh` installs `~/.config/new-proj/shell-integration.zsh` and appends a `source` line to `~/.zshrc` when missing; that wrapper runs the binary and `eval`s the `cd` line in the interactive shell.
- New projects get root `AGENTS.md` and `README.md`, project docs under `docs/` (or `SCAFFOLD_DIR_NAME`), plus `.gitignore`, copied from user templates in `~/.config/new-proj/templates/`.
- This repo (`quick-project-start`) is the versioned source for `new-proj` and `install.sh`; it is not installed in place — `install.sh` copies the script to `~/.local/bin`.

## Repository layout

```
quick-project-start/
  new-proj          # CLI: create project dir, copy templates, git + gh
  install.sh        # Install new-proj globally; seed ~/.config/new-proj if missing
  AGENTS.md         # Agent rules (repo root; Cursor convention)
  README.md         # Human-facing usage for this repo
  tests/            # ./tests/run-tests.sh
  docs/
    ARCHITECTURE.md # This file
    DEPLOY.md       # Install / update flow
    TODO.md         # Open decisions for this tool
```

## Runtime layout (after install)

| Path | Role |
|------|------|
| `~/.local/bin/new-proj` | Installed copy of `new-proj` (from last `./install.sh`) |
| `~/.config/new-proj/config.env` | Defaults: `SCAFFOLD_DIR_NAME`, optional `BASE_DIR`, `TEMPLATES_DIR` |
| `~/.config/new-proj/templates/` | `AGENTS.md`, `ARCHITECTURE.md`, `README.md`, `DEPLOY.md`, `TODO.md`, `.gitignore` — copied into each new project (`AGENTS.md` and `README.md` at project root; others under scaffold dir) |
| `~/.config/new-proj/bundled/AGENTS.md` | Refreshed on every `./install.sh`; source for `new-proj --agent-upgrade` when not running from a checkout |

Per-run env overrides: `NEW_PROJ_BASE_DIR`, `NEW_PROJ_SCAFFOLD_DIR_NAME`, `NEW_PROJ_TEMPLATES_DIR`, `NEW_PROJ_CONFIG_FILE`.

## What `new-proj` creates

For `new-proj "my-app"` with defaults:

```
~/Documents/coding-temp/my-app/
  AGENTS.md              # from templates (project root)
  README.md
  .gitignore
  docs/
    ARCHITECTURE.md      # empty template unless customized in ~/.config
    DEPLOY.md
    TODO.md
```

If `git` / `gh` are missing or `gh repo create` fails, the directory and files are still created; warnings are printed.

## Flow

```mermaid
flowchart LR
  subgraph repo["quick-project-start repo"]
    install["install.sh"]
    script["new-proj"]
  end
  subgraph global["~/.config/new-proj"]
    cfg["config.env"]
    tpl["templates/"]
  end
  subgraph out["new project"]
    root["AGENTS.md README.md .gitignore"]
    scaffold["docs/*"]
    git["git init + gh repo create"]
  end
  install -->|"cp new-proj"| bin["~/.local/bin/new-proj"]
  install -->|"seed if missing"| tpl
  bin --> script
  script --> tpl
  script --> root
  script --> scaffold
  script --> git
```

## Decisions

- **Stack**: Bash only; no runtime dependencies beyond `git` and optional `gh`.
- **Templates live outside the repo** after first `install.sh`, so each machine can customize defaults without this repo overwriting them.
- **This repo’s `docs/`** hold project docs; **`AGENTS.md` at repo root** holds agent rules. `install.sh` seeds global templates from repo `AGENTS.md` but does not modify this repo’s `docs/` on install.
- **Tests**: `tests/run-tests.sh` uses isolated `HOME`, temp base/templates dirs, and a fake `gh` on `PATH`.
- **`AGENTS.md` and `README.md` at project root** for new projects; `ARCHITECTURE.md`, `DEPLOY.md`, and `TODO.md` stay under `docs/` (or `SCAFFOLD_DIR_NAME`).
- **`new-proj`** seeds `AGENTS.md` from repo `AGENTS.md` when run from a checkout, else from `~/.config/new-proj/templates/`, else an embedded fallback heredoc.
- **`--existing`**: target is `pwd`; no project name required (GitHub repo name defaults to directory basename); runs git/GitHub unless `--no-repo`; skips `gh repo create` when `origin` is already set or the named GitHub repo already exists (links origin and pushes instead).
