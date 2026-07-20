# quick-proj — agent architecture reference

## Product intent

- Bash CLI scaffolds new coding projects under configurable base directory (default `~/Documents/coding-temp`).
- Default run: local git repo, `init` commit on `main`, public GitHub repo via `gh` when available. `--no-repo` skips git/GitHub.
- `--existing` from inside a project: copy scaffold into cwd; git/GitHub unless `--no-repo`; preserve existing root `README.md`, `.gitignore`, `scaffold/PROJECT-KNOWLEDGE.md`, and legacy `docs/` files; no `cd`.
- `--update`: refresh scaffold agent files and root `AGENTS.md`; add missing scaffold files; never delete; resolve root via `git rev-parse --show-toplevel` or walk up to nearest `scaffold/AGENT-WORKFLOW.md` (or legacy root `AGENTS.md` with version line only).
- `--agent-version`: print project vs latest `scaffold version: X.Y.Z` from `scaffold/AGENT-WORKFLOW.md` last line; exit 0 on match.
- `scaffold/AGENT-WORKFLOW.md` ends with `scaffold version: X.Y.Z`; bump on template changes. Agents do not edit agent workflow files in scaffolded projects.
- Normal runs print `cd` on stdout; `install.sh` adds zsh shell integration to eval `cd`.
- New projects: root `AGENTS.md` (pointer to scaffold/), `README.md`, `.gitignore`, `scripts/sz.py`; scaffold files under `scaffold/` (or `SCAFFOLD_DIR_NAME`); templates from `~/.config/quick-proj/templates/`.
- This repo is versioned source; `install.sh` copies to `~/.local/bin`.

## Repository layout

```
quick-project-start/
  quick-proj
  install.sh
  README.md
  templates/
  scaffold/
    AGENT-COMMS.md
    AGENT-WORKFLOW.md
    ARCH-HUMAN.md
    ARCH-LLM.md
    PROJECT-KNOWLEDGE.md
    skills/
  tests/
```

## Runtime layout (after install)

| Path | Role |
|------|------|
| `~/.local/bin/quick-proj` | Installed CLI |
| `~/.config/quick-proj/config.env` | `SCAFFOLD_DIR_NAME` (default `scaffold`), optional `BASE_DIR`, `TEMPLATES_DIR` |
| `~/.config/quick-proj/templates/` | Scaffold templates synced on every `./install.sh` |
| `~/.config/quick-proj/bundled/` | `AGENT-COMMS.md`, `AGENT-WORKFLOW.md` for `--update` when not in checkout |

Per-run env: `QUICK_PROJ_BASE_DIR`, `QUICK_PROJ_SCAFFOLD_DIR_NAME`, `QUICK_PROJ_TEMPLATES_DIR`, `QUICK_PROJ_CONFIG_FILE`. Legacy `NEW_PROJ_*` names still honored.

## Scaffold files created per project

Root: `README.md`, `.gitignore`, `scripts/sz.py`

Under scaffold dir:
- `AGENT-COMMS.md`, `AGENT-WORKFLOW.md` (overwritten on `--update`)
- `ARCH-HUMAN.md`, `ARCH-LLM.md`, `PROJECT-KNOWLEDGE.md` (added if missing; not overwritten on `--update`)
- `skills/` (empty dir)

Legacy: `docs/ARCHITECTURE.md`, `docs/KNOWLEDGE.md`, root `AGENTS.md` — not removed by `--update`; new projects use `scaffold/` only.

`DEPLOY.md` / `TODO.md` deprecated; not scaffolded.

## Install flow

1. `./install.sh` → `~/.local/bin/quick-proj`, migrate `~/.config/new-proj` if present, sync templates + bundled agent files, create `config.env` if missing.
2. `git pull && ./install.sh` refreshes everything.
3. `quick-proj --update` in an existing project refreshes agent files only.

## Decisions

- **Stack**: Bash; `git` + optional `gh`; `sz.py` Python 3 stdlib only.
- **Templates synced every install** — no stale `~/.config/quick-proj/templates/`.
- **Tests**: `tests/run-tests.sh` — isolated `HOME`, temp dirs, fake `gh`.
- **`--existing`**: `pwd` target; GitHub name = dir basename; skip `gh repo create` if `origin` exists or repo exists.
- **`--update`**: overwrites `AGENT-COMMS.md`, `AGENT-WORKFLOW.md`, and root `AGENTS.md` only; additive for other scaffold files.
- **Project root discovery**: git toplevel, else walk up for `{scaffold_dir}/AGENT-WORKFLOW.md`, else legacy `AGENTS.md`.
