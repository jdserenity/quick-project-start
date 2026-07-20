# quick-proj — agent architecture reference

## Product intent

- Bash CLI scaffolds new coding projects under configurable base directory (default `~/Documents/coding-temp`).
- Default run: local git repo, `init` commit on `main`, public GitHub repo via `gh` when available. `--no-repo` skips git/GitHub.
- `--existing` from inside a project: copy scaffold into cwd; git/GitHub unless `--no-repo`; preserve existing root `README.md`, `.gitignore`; migrate legacy `docs/` → `scaffold/` when present; no `cd`.
- `--update`: refresh scaffold agent files and root `AGENTS.md`; add missing scaffold files; never delete; rename `docs/` → `scaffold/` when `docs/` exists and `scaffold/` does not; resolve root via `git rev-parse --show-toplevel` or walk up to nearest `scaffold/AGENT-WORKFLOW.md` / `docs/AGENT-WORKFLOW.md` / root `AGENTS.md`.
- `--agent-version`: print project vs latest `scaffold version: X.Y.Z` from `scaffold/AGENT-WORKFLOW.md` last line; exit 0 on match.
- Version line `scaffold version: X.Y.Z` lives on `templates/AGENT-WORKFLOW.md` (copied into each project's `scaffold/AGENT-WORKFLOW.md`). Bump **patch** for small template edits; **minor** only for substantive new agent policy; **major** only for breaking scaffold changes.
- Agent rules have one home in this repo: `templates/AGENT-COMMS.md` + `templates/AGENT-WORKFLOW.md`. This repo's `scaffold/AGENT-*.md` are consumer copies synced by `./install.sh`.
- Normal runs print `cd` on stdout; `install.sh` adds zsh shell integration to eval `cd`.
- New projects: root `AGENTS.md` (pointer to scaffold/), `README.md`, `.gitignore`, `scripts/sz.py`; scaffold files under `scaffold/` (or `SCAFFOLD_DIR_NAME`, except legacy `"docs"` which is treated as `"scaffold"`).
- This repo is versioned source; `install.sh` copies CLI + `lib/` to `~/.local`.

## Repository layout

```
quick-project-start/
  quick-proj          # entrypoint (arg parse + dispatch)
  lib/                # sourced modules
    config.sh
    version.sh
    agents.sh
    scaffold.sh
    update.sh
    git.sh
  install.sh
  README.md
  templates/          # product source (agent rules + blank project files)
    AGENT-COMMS.md
    AGENT-WORKFLOW.md
  scaffold/           # this repo's project docs + synced agent-rule copies
    AGENT-COMMS.md    # synced from templates/ by install.sh
    AGENT-WORKFLOW.md
    ARCH-HUMAN.md
    ARCH-LLM.md
    skills/
  tests/
```

## Runtime layout (after install)

| Path | Role |
|------|------|
| `~/.local/bin/quick-proj` | Installed CLI entrypoint |
| `~/.local/share/quick-proj/lib/` | Installed modules |
| `~/.config/quick-proj/config.env` | `SCAFFOLD_DIR_NAME` (default `scaffold`; `"docs"` rewritten to `scaffold`), optional `BASE_DIR`, `TEMPLATES_DIR` |
| `~/.config/quick-proj/templates/` | All project templates including agent rules; synced from repo `templates/` on every `./install.sh` |
| `~/.config/quick-proj/bundled/` | Legacy mirror of agent rules (still refreshed on install) for older `--update` paths |

Per-run env: `QUICK_PROJ_BASE_DIR`, `QUICK_PROJ_SCAFFOLD_DIR_NAME`, `QUICK_PROJ_TEMPLATES_DIR`, `QUICK_PROJ_CONFIG_FILE`.

## Scaffold files created per project

Root: `README.md`, `.gitignore`, `scripts/sz.py`

Under scaffold dir:
- `AGENT-COMMS.md`, `AGENT-WORKFLOW.md` (from checkout `templates/` or installed templates/; overwritten on `--update`)
- `ARCH-HUMAN.md`, `ARCH-LLM.md` (from templates/; added if missing; not overwritten on `--update`)
- `skills/` (empty dir)

`PROJECT-KNOWLEDGE.md` removed from the scaffold; lessons go in ARCH files. `DEPLOY.md` / `TODO.md` deprecated; not scaffolded.

## Install flow

1. `./install.sh` → `~/.local/bin/quick-proj` + `~/.local/share/quick-proj/lib/`, sync repo `templates/` → `~/.config/quick-proj/templates/` (+ agent rules into `bundled/` and this checkout's `scaffold/AGENT-*.md`), create/fix `config.env` (`docs` → `scaffold`).
2. `git pull && ./install.sh` refreshes everything.
3. `quick-proj --update` in an existing project refreshes agent files; migrates `docs/` → `scaffold/` when needed.

## Decisions

- **Stack**: Bash; `git` + optional `gh`; `sz.py` Python 3 stdlib only.
- **Modular CLI**: entrypoint + `lib/*.sh` (not a single opaque script).
- **Agent rules DRY**: edit only `templates/AGENT-COMMS.md` / `templates/AGENT-WORKFLOW.md`; install syncs to installed templates, bundled, and this repo's scaffold copies; source order checkout templates → templates_dir → bundled → embedded stub (`0.0.0`).
- **Templates synced every install** — no stale `~/.config/quick-proj/templates/`.
- **Tests**: `tests/run-tests.sh` — isolated `HOME`, temp dirs, fake `gh`.
- **`--existing`**: `pwd` target; GitHub name = dir basename; skip `gh repo create` if `origin` exists or repo exists.
- **`--update`**: overwrites `AGENT-COMMS.md`, `AGENT-WORKFLOW.md`, and root `AGENTS.md` only; additive for other scaffold files; `docs/` → `scaffold/` rename when safe.
- **Project root discovery**: git toplevel, else walk up for `{scaffold_dir}/AGENT-WORKFLOW.md`, `docs/AGENT-WORKFLOW.md`, or `AGENTS.md`.
