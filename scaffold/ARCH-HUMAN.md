# quick-proj

## What this is

`quick-proj` is a command you run in the terminal. It creates a new coding project folder with a standard layout: agent rules, architecture notes, a README, git, and (if you have GitHub CLI set up) a GitHub repo.

This repo (`quick-project-start`) is where that command is built and maintained. Running `./install.sh` copies it to `~/.local/bin/quick-proj` on your machine (and the supporting `lib/` modules next to it under `~/.local/share/quick-proj/`).

## Install and update

```bash
cd /path/to/quick-project-start
./install.sh
```

After pulling changes:

```bash
git pull
./install.sh
```

## Commands

| Command | What it does |
|---------|--------------|
| `quick-proj "my-app"` | Creates `~/Documents/coding-temp/my-app/` with scaffold files, git, and GitHub |
| `quick-proj --no-repo "my-app"` | Same but skips git and GitHub |
| `quick-proj --existing` | Adds scaffold files to the current directory |
| `quick-proj --update` | Refreshes agent rules, adds missing scaffold files, and renames a leftover `docs/` folder to `scaffold/` when needed |
| `quick-proj --agent-version` | Shows whether your project's scaffold rules are up to date |

## What a new project looks like

```
my-app/
  README.md
  .gitignore
  scripts/sz.py
  scaffold/
    AGENT-COMMS.md       # how agents should talk to you
    AGENT-WORKFLOW.md    # how agents should work
    ARCH-HUMAN.md        # architecture for humans (this kind of file)
    ARCH-LLM.md          # architecture for agents
    skills/              # empty; agent skills go here later
```

Root `AGENTS.md` points agents at `scaffold/` and says scaffold rules override everything else.

## This repo's layout

```
quick-project-start/
  quick-proj        # CLI entrypoint
  lib/              # modules the entrypoint loads
  install.sh        # installs quick-proj globally
  README.md         # usage for this repo
  templates/        # blank project files (README, ARCH stubs, etc.) — not agent rules
  scaffold/         # agent rules (edit here only) + this project's docs
  tests/
```

When you change agent rules, edit only `scaffold/AGENT-COMMS.md` or `scaffold/AGENT-WORKFLOW.md`, bump the version line at the bottom of `AGENT-WORKFLOW.md`, then run `./install.sh`. That copies the rules into `~/.config/quick-proj/bundled/` so other projects can pick them up with `quick-proj --update`.

## Configure defaults

Edit `~/.config/quick-proj/config.env`:

- `SCAFFOLD_DIR_NAME="scaffold"` — folder name for project docs (default). The old value `"docs"` is treated as `"scaffold"`.
- `BASE_DIR` — where new projects are created
- `TEMPLATES_DIR` — override template source

## Tests

```bash
./tests/run-tests.sh
```
